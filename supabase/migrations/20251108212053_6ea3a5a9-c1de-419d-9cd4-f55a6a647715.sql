-- Add unique constraint to user_plans.user_id for upsert functionality
ALTER TABLE public.user_plans DROP CONSTRAINT IF EXISTS user_plans_user_id_key;
ALTER TABLE public.user_plans ADD CONSTRAINT user_plans_user_id_key UNIQUE (user_id);

-- Ensure updated_at trigger exists for user_plans
DROP TRIGGER IF EXISTS update_user_plans_updated_at ON public.user_plans;
CREATE TRIGGER update_user_plans_updated_at
  BEFORE UPDATE ON public.user_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();