# Database Setup for Try-On Outfits

## Create the `try_on_outfits` Table

You need to create a table in Supabase to store saved outfits.

### Step 1: Go to SQL Editor
**Click:** https://supabase.com/dashboard/project/pdhmakamlgsosiubivzk/sql/new

### Step 2: Run This SQL

Copy and paste this SQL command:

```sql
-- Create try_on_outfits table
CREATE TABLE IF NOT EXISTS public.try_on_outfits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    image_url TEXT NOT NULL,
    clothing_type TEXT NOT NULL,
    fit_style TEXT NOT NULL,
    clothing_state TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_try_on_outfits_user_id
ON public.try_on_outfits(user_id);

-- Create index on created_at for ordering
CREATE INDEX IF NOT EXISTS idx_try_on_outfits_created_at
ON public.try_on_outfits(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.try_on_outfits ENABLE ROW LEVEL SECURITY;

-- Create policy: Users can view their own outfits
CREATE POLICY "Users can view own outfits"
ON public.try_on_outfits
FOR SELECT
USING (true);

-- Create policy: Users can insert their own outfits
CREATE POLICY "Users can insert own outfits"
ON public.try_on_outfits
FOR INSERT
WITH CHECK (true);

-- Create policy: Users can delete their own outfits
CREATE POLICY "Users can delete own outfits"
ON public.try_on_outfits
FOR DELETE
USING (true);
```

### Step 3: Click "Run"

That's it! Your database is ready.

---

## What This Creates

### Table Structure:
- **id**: Unique identifier for each outfit
- **user_id**: Clerk user ID (links outfit to user)
- **image_url**: URL of the saved image in Supabase storage
- **clothing_type**: Type of clothing (T-Shirt, Jacket, etc.)
- **fit_style**: Fit style (Regular, Oversized, etc.)
- **clothing_state**: Open/Closed (optional)
- **created_at**: Timestamp when outfit was saved

### Indexes:
- Fast lookups by user_id
- Fast sorting by created_at

### Security:
- Row Level Security (RLS) enabled
- Policies allow users to see/add/delete outfits
- (Note: Current policies allow all users - you can restrict later)

---

## Testing

After running the SQL:

1. Save a try-on result in the app
2. Go to HomeView
3. You should see it in "Recent Outfits" section!

---

## Troubleshooting

### "relation already exists"
The table is already created. You're good!

### "permission denied"
Make sure you're logged in to Supabase dashboard.

### No outfits showing up
- Check that you've saved at least one outfit
- Make sure you're signed in with Clerk
- Check browser console for errors
