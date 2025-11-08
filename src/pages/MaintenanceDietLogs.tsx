import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { ArrowLeft, Coffee, Apple, Beef, Salad, Moon, Calendar, Plus, Trash2, Lock } from 'lucide-react';
import logo from '@/assets/fitin-final-logo.jpg';
import { toast } from 'sonner';
import { supabase } from '@/integrations/supabase/client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

const MaintenanceDietLogs = () => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [isAdmin, setIsAdmin] = useState(false);

  // Check admin role
  useEffect(() => {
    const checkAdmin = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .eq('role', 'admin')
        .single();

      setIsAdmin(!!data);
    };
    checkAdmin();
  }, []);

  // Fetch user goals
  const { data: userGoals } = useQuery({
    queryKey: ['user-goals'],
    queryFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      
      const { data, error } = await supabase
        .from('user_goals')
        .select('*')
        .eq('user_id', user.id)
        .single();
      
      if (error) throw error;
      return data;
    },
  });

  // Fetch meal logs
  const { data: mealLogs = [] } = useQuery({
    queryKey: ['meal-logs', selectedDate],
    queryFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      
      const { data, error } = await supabase
        .from('meal_logs')
        .select('*')
        .eq('user_id', user.id)
        .eq('logged_at', selectedDate)
        .order('created_at', { ascending: true });
      
      if (error) throw error;
      return data || [];
    },
  });

  // Real-time updates for meal logs
  useEffect(() => {
    const channel = supabase
      .channel('meal-logs-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'meal_logs',
        },
        () => {
          queryClient.invalidateQueries({ queryKey: ['meal-logs', selectedDate] });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [selectedDate, queryClient]);

  // Calculate totals
  const totals = mealLogs.reduce(
    (acc, meal) => ({
      calories: acc.calories + meal.calories,
      protein: acc.protein + parseFloat(meal.protein.toString()),
      carbs: acc.carbs + parseFloat(meal.carbs.toString()),
      fat: acc.fat + parseFloat(meal.fat.toString()),
    }),
    { calories: 0, protein: 0, carbs: 0, fat: 0 }
  );

  const mealTypes = [
    { id: 'breakfast', name: 'Breakfast', icon: Coffee, time: '8:00 AM' },
    { id: 'mid-morning', name: 'Mid-Morning Snack', icon: Apple, time: '10:30 AM' },
    { id: 'lunch', name: 'Lunch', icon: Beef, time: '12:30 PM' },
    { id: 'snack', name: 'Evening Snack', icon: Salad, time: '4:00 PM' },
    { id: 'dinner', name: 'Dinner', icon: Moon, time: '7:30 PM' },
  ];

  const nutritionGoals = [
    { label: 'Calories', value: userGoals?.target_calories ?? 2100, current: totals.calories, color: 'text-primary' },
    { label: 'Protein', value: userGoals?.protein_grams ?? 130, unit: 'g', current: Math.round(totals.protein), color: 'text-green-500' },
    { label: 'Carbs', value: userGoals?.carbs_grams ?? 230, unit: 'g', current: Math.round(totals.carbs), color: 'text-blue-500' },
    { label: 'Fat', value: userGoals?.fat_grams ?? 60, unit: 'g', current: Math.round(totals.fat), color: 'text-yellow-500' },
  ];

  // Add meal mutation
  const addMealMutation = useMutation({
    mutationFn: async ({ mealType, mealName, calories, protein, carbs, fat }: any) => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { error } = await supabase
        .from('meal_logs')
        .insert({
          user_id: user.id,
          meal_name: mealName,
          calories: parseInt(calories),
          protein: parseFloat(protein),
          carbs: parseFloat(carbs),
          fat: parseFloat(fat),
          meal_type: mealType,
          logged_at: selectedDate,
        });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['meal-logs', selectedDate] });
      toast.success('Meal added successfully');
    },
  });

  // Delete meal mutation
  const deleteMealMutation = useMutation({
    mutationFn: async (mealId: string) => {
      const { error } = await supabase
        .from('meal_logs')
        .delete()
        .eq('id', mealId);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['meal-logs', selectedDate] });
      toast.success('Meal deleted');
    },
  });

  const [editingMeals, setEditingMeals] = useState<Record<string, any>>({});

  const handleAddMeal = (mealType: string, data: any) => {
    // All users can log meals
    addMealMutation.mutate({ mealType, ...data });
  };

  return (
    <div className="min-h-screen bg-gradient-dark">
      {/* Header */}
      <div className="border-b border-border/50 bg-background/50 backdrop-blur-md sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button
                variant="ghost"
                onClick={() => navigate('/premium/dashboard')}
                className="text-muted-foreground hover:text-primary"
              >
                <ArrowLeft className="w-5 h-5" />
              </Button>
              <img src={logo} alt="FitIn" className="h-10 w-auto" />
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-12">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
        >
          <div className="flex items-center justify-between mb-8">
            <div>
              <h1 className="text-4xl font-bold mb-2">
                <span className="text-gradient">Maintenance Diet Plan</span>
              </h1>
              <p className="text-muted-foreground text-lg">
                5 meals per day • Maintain current weight
              </p>
            </div>
            <Card className="glass-card px-6 py-3 rounded-xl">
              <Input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="border-0 bg-transparent"
              />
            </Card>
          </div>

          <div className="grid lg:grid-cols-3 gap-6">
            {/* Nutrition Overview */}
            <div className="lg:col-span-1">
              <Card className="glass-card p-8 rounded-2xl">
                <h2 className="text-2xl font-bold mb-6">Daily Goals</h2>
                <div className="space-y-6">
                  {nutritionGoals.map((goal) => (
                    <div key={goal.label}>
                      <div className="flex justify-between mb-2">
                        <span className="text-sm font-medium">{goal.label}</span>
                        <span className={`text-sm font-bold ${goal.color}`}>
                          {goal.current} / {goal.value}{goal.unit || ' cals'}
                        </span>
                      </div>
                      <div className="h-2 bg-background/50 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-gradient-to-r from-primary to-primary/50 rounded-full transition-all duration-500"
                          style={{ width: `${Math.min((goal.current / goal.value) * 100, 100)}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </Card>
            </div>

            {/* Meal Logging */}
            <div className="lg:col-span-2 space-y-6">
              {mealTypes.map((meal) => {
                const mealsOfType = mealLogs.filter(m => m.meal_type === meal.id);

                return (
                  <Card key={meal.id} className="glass-card p-6 rounded-2xl">
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex items-center gap-4">
                        <div className="bg-primary/10 p-3 rounded-lg">
                          <meal.icon className="w-6 h-6 text-primary" />
                        </div>
                        <div>
                          <h3 className="text-xl font-bold">{meal.name}</h3>
                          <p className="text-sm text-muted-foreground">{meal.time}</p>
                        </div>
                      </div>
                    </div>

                    {/* Logged meals */}
                    {mealsOfType.map((loggedMeal) => (
                      <div key={loggedMeal.id} className="mb-3 p-3 bg-background/30 rounded-lg border border-border/30">
                        <div className="flex items-center justify-between">
                          <div>
                            <p className="font-semibold">{loggedMeal.meal_name}</p>
                            <p className="text-sm text-muted-foreground">
                              {loggedMeal.calories} kcal • P: {loggedMeal.protein}g • C: {loggedMeal.carbs}g • F: {loggedMeal.fat}g
                            </p>
                          </div>
                           <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => deleteMealMutation.mutate(loggedMeal.id)}
                              className="text-destructive"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                        </div>
                      </div>
                    ))}

                    {/* Add meal form - available to all users */}
                    <div className="space-y-2 mt-4">
                        <Input
                          placeholder="Meal name"
                          onChange={(e) => setEditingMeals({ ...editingMeals, [meal.id]: { ...editingMeals[meal.id], name: e.target.value } })}
                        />
                        <div className="grid grid-cols-4 gap-2">
                          <Input
                            type="number"
                            placeholder="Cal"
                            onChange={(e) => setEditingMeals({ ...editingMeals, [meal.id]: { ...editingMeals[meal.id], calories: e.target.value } })}
                          />
                          <Input
                            type="number"
                            placeholder="P"
                            onChange={(e) => setEditingMeals({ ...editingMeals, [meal.id]: { ...editingMeals[meal.id], protein: e.target.value } })}
                          />
                          <Input
                            type="number"
                            placeholder="C"
                            onChange={(e) => setEditingMeals({ ...editingMeals, [meal.id]: { ...editingMeals[meal.id], carbs: e.target.value } })}
                          />
                          <Input
                            type="number"
                            placeholder="F"
                            onChange={(e) => setEditingMeals({ ...editingMeals, [meal.id]: { ...editingMeals[meal.id], fat: e.target.value } })}
                          />
                        </div>
                        <Button
                          size="sm"
                          className="w-full"
                          onClick={() => {
                            const data = editingMeals[meal.id];
                            if (!data?.name || !data?.calories || !data?.protein || !data?.carbs || !data?.fat) {
                              toast.error('Fill all fields');
                              return;
                            }
                            handleAddMeal(meal.id, { mealName: data.name, calories: data.calories, protein: data.protein, carbs: data.carbs, fat: data.fat });
                            setEditingMeals({ ...editingMeals, [meal.id]: {} });
                          }}
                        >
                          <Plus className="w-4 h-4 mr-2" />
                          Add
                        </Button>
                      </div>
                  </Card>
                );
              })}
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default MaintenanceDietLogs;
