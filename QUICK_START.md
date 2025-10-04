# 🚀 Quick Start Guide

## To See Photos on Homepage

You need to create the database table first!

### Do This Now (2 minutes):

1. **Open Supabase SQL Editor:**
   https://supabase.com/dashboard/project/pdhmakamlgsosiubivzk/sql/new

2. **Copy this SQL and click "Run":**

```sql
CREATE TABLE IF NOT EXISTS public.try_on_outfits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    image_url TEXT NOT NULL,
    clothing_type TEXT NOT NULL,
    fit_style TEXT NOT NULL,
    clothing_state TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_try_on_outfits_user_id ON public.try_on_outfits(user_id);
CREATE INDEX IF NOT EXISTS idx_try_on_outfits_created_at ON public.try_on_outfits(created_at DESC);

ALTER TABLE public.try_on_outfits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all for now" ON public.try_on_outfits FOR ALL USING (true) WITH CHECK (true);
```

3. **Done!** Now your app will save and show photos.

---

## ✅ What's Fixed

### 1. Photos on Homepage
- Empty state shows "No outfits yet" when database is empty
- Once you save a photo, it appears here

### 2. Cancel & Restart Button
- After selecting both photos and clothing options
- Tap "Cancel & Restart" to start over

### 3. Fixed UI Issues
- Clothing options now limited to 280pt height
- Page is scrollable - no navbar overlap
- Generate button always accessible

---

## 📱 Full Flow

1. **Camera Tab** → Take/choose 2 photos
2. **Select clothing options** (Type, Fit, State)
3. **Generate** → AI processes
4. **ResultView** → Keep (saves to cloud) or Discard
5. **Home Tab** → See all your saved outfits!

---

## ⚠️ Still Can't See Photos?

Check these:

1. **Database table created?**
   - Go to: https://supabase.com/dashboard/project/pdhmakamlgsosiubivzk/editor
   - Look for `try_on_outfits` table

2. **Saved at least one outfit?**
   - Use the Camera tab
   - Complete the flow and tap "Keep Photo"

3. **Signed in with Clerk?**
   - App requires authentication
   - Check if you're logged in

4. **Check console for errors:**
   - Open Xcode console while running app
   - Look for any Supabase errors
