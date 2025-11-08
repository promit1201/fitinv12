
-- Migration: 20251108200724

-- Migration: 20251107192946
-- Create enum for roles
CREATE TYPE public.app_role AS ENUM ('admin', 'user');

-- Create user_roles table
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (user_id, role)
);

-- Enable RLS
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Create security definer function to check roles
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- RLS policies for user_roles
CREATE POLICY "Users can view their own roles"
  ON public.user_roles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Create user_details table
CREATE TABLE public.user_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  height NUMERIC NOT NULL CHECK (height >= 100 AND height <= 250),
  weight NUMERIC NOT NULL CHECK (weight >= 30 AND weight <= 300),
  age INTEGER NOT NULL CHECK (age >= 13 AND age <= 100),
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  activity_level TEXT NOT NULL CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_details ENABLE ROW LEVEL SECURITY;

-- RLS policies for user_details
CREATE POLICY "Users can view their own details"
  ON public.user_details
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own details"
  ON public.user_details
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own details"
  ON public.user_details
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Create user_goals table
CREATE TABLE public.user_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  goal_type TEXT NOT NULL CHECK (goal_type IN ('cut', 'bulk', 'maintain')),
  maintenance_calories INTEGER NOT NULL,
  target_calories INTEGER NOT NULL,
  protein_grams INTEGER NOT NULL,
  carbs_grams INTEGER NOT NULL,
  fat_grams INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;

-- RLS policies for user_goals
CREATE POLICY "Users can view their own goals"
  ON public.user_goals
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own goals"
  ON public.user_goals
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals"
  ON public.user_goals
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_details_updated_at
  BEFORE UPDATE ON public.user_details
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_goals_updated_at
  BEFORE UPDATE ON public.user_goals
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Migration: 20251108195812
-- Create user_plans table
CREATE TABLE public.user_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('free', 'paid')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE public.user_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own plan"
  ON public.user_plans FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own plan"
  ON public.user_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plan"
  ON public.user_plans FOR UPDATE
  USING (auth.uid() = user_id);

-- Create rest_days table
CREATE TABLE public.rest_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rest_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(user_id, rest_date)
);

ALTER TABLE public.rest_days ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own rest days"
  ON public.rest_days FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own rest days"
  ON public.rest_days FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own rest days"
  ON public.rest_days FOR DELETE
  USING (auth.uid() = user_id);

-- Create workout_logs table
CREATE TABLE public.workout_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_type TEXT NOT NULL,
  sets INTEGER NOT NULL CHECK (sets > 0),
  reps INTEGER NOT NULL CHECK (reps > 0),
  weight NUMERIC NOT NULL CHECK (weight >= 0),
  logged_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own workout logs"
  ON public.workout_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout logs"
  ON public.workout_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout logs"
  ON public.workout_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workout logs"
  ON public.workout_logs FOR DELETE
  USING (auth.uid() = user_id);

-- Create meal_logs table
CREATE TABLE public.meal_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  meal_name TEXT NOT NULL,
  calories INTEGER NOT NULL CHECK (calories >= 0),
  protein NUMERIC NOT NULL CHECK (protein >= 0),
  carbs NUMERIC NOT NULL CHECK (carbs >= 0),
  fat NUMERIC NOT NULL CHECK (fat >= 0),
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  logged_at DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.meal_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own meal logs"
  ON public.meal_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own meal logs"
  ON public.meal_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own meal logs"
  ON public.meal_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own meal logs"
  ON public.meal_logs FOR DELETE
  USING (auth.uid() = user_id);

-- Admins can view all meal logs
CREATE POLICY "Admins can view all meal logs"
  ON public.meal_logs FOR SELECT
  USING (public.has_role(auth.uid(), 'admin'));

-- Admins can update all meal logs
CREATE POLICY "Admins can update all meal logs"
  ON public.meal_logs FOR UPDATE
  USING (public.has_role(auth.uid(), 'admin'));

-- Admins can delete all meal logs
CREATE POLICY "Admins can delete all meal logs"
  ON public.meal_logs FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));

-- Create food_items table (for meal planning)
CREATE TABLE public.food_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  food_name TEXT NOT NULL,
  calories INTEGER NOT NULL CHECK (calories >= 0),
  protein NUMERIC NOT NULL CHECK (protein >= 0),
  carbs NUMERIC NOT NULL CHECK (carbs >= 0),
  fat NUMERIC NOT NULL CHECK (fat >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own food items"
  ON public.food_items FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own food items"
  ON public.food_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own food items"
  ON public.food_items FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own food items"
  ON public.food_items FOR DELETE
  USING (auth.uid() = user_id);

-- Create triggers for updated_at
CREATE TRIGGER update_user_plans_updated_at
  BEFORE UPDATE ON public.user_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Enable realtime for meal_logs and workout_logs
ALTER PUBLICATION supabase_realtime ADD TABLE public.meal_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.workout_logs;


-- Migration: 20251108202008
-- Assign admin role to FitIn.simplified@gmail.com
-- This will only insert if the user exists and doesn't already have the admin role
INSERT INTO user_roles (user_id, role)
SELECT id, 'admin'::app_role 
FROM auth.users
WHERE email = 'FitIn.simplified@gmail.com'
ON CONFLICT (user_id, role) DO NOTHING;

-- Migration: 20251108205134
-- Add a comment to trigger types regeneration
COMMENT ON TABLE public.user_roles IS 'Stores user role assignments for access control';
COMMENT ON TABLE public.meal_logs IS 'Tracks user meal entries with nutritional information';
COMMENT ON TABLE public.user_goals IS 'Stores user fitness goals and target macros';
COMMENT ON TABLE public.user_details IS 'Contains user profile information for calorie calculations';
COMMENT ON TABLE public.rest_days IS 'Tracks scheduled rest days for users';
COMMENT ON TABLE public.workout_logs IS 'Records workout session data and progress';
