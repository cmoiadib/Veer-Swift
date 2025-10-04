# Supabase Storage Setup Guide

## ⚠️ URGENT: Fix "Bucket not found" Error

Your app is trying to upload to a storage bucket that doesn't exist yet.

## 🚀 Quick Fix (3 minutes)

### Step 1: Open Supabase Dashboard
**Click this link:** https://supabase.com/dashboard/project/pdhmakamlgsosiubivzk/storage/buckets

### Step 2: Create the Bucket (if not done)
1. Click the green **"New bucket"** button
2. Enter these settings:
   ```
   Name: user-photos
   Public bucket: ON ✓
   File size limit: 50MB
   ```
3. Click **"Create bucket"**

### Step 3: FIX RLS POLICY ERROR ⚠️
The "row-level security policy" error means you need to allow uploads.

**Click this link:** https://supabase.com/dashboard/project/pdhmakamlgsosiubivzk/storage/policies

1. Find the **"user-photos"** bucket
2. Click **"New Policy"**
3. Choose **"For full customization"**
4. Fill in:
   ```
   Policy name: Allow all uploads
   Target roles: public
   Policy definition: true
   Allowed operations: INSERT ✓
   ```
5. Click **"Create policy"**

**OR** Disable RLS (easier for testing):
1. Click on **"user-photos"** bucket
2. Find **"RLS enabled"** toggle
3. Turn it **OFF**

**Done!** Your app will now save photos.

### Step 3: Set Up Policies (Optional but Recommended)

After creating the bucket, set up Row Level Security (RLS) policies:

#### Allow Authenticated Users to Upload
```sql
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-photos' AND
  (storage.foldername(name))[1] = 'try-on-images'
);
```

#### Allow Public Read Access
```sql
CREATE POLICY "Allow public downloads"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'user-photos');
```

#### Allow Users to Delete Their Own Files
```sql
CREATE POLICY "Allow authenticated deletes"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### Step 4: Test the Upload

1. Run your app
2. Complete the try-on generation
3. Tap **"Keep Photo"**
4. The photo should now upload successfully!

### Step 5: Verify Upload in Dashboard

1. Go back to Supabase Dashboard → Storage → user-photos
2. Navigate to `try-on-images/` folder
3. You should see your uploaded images with filenames like:
   - `tryon_user_abc123_1234567890.jpg`

## Folder Structure

Your storage will be organized like this:
```
user-photos/                    <- Bucket
└── try-on-images/              <- Folder
    ├── tryon_user_abc123_1234567890.jpg
    ├── tryon_user_def456_1234567891.jpg
    └── ...
```

## Troubleshooting

### Error: "Bucket already exists"
- The bucket name must be unique. If you get this error, the bucket already exists. Check if it's there in the Storage tab.

### Error: "Policy violation"
- Make sure you've created the RLS policies above
- Or temporarily disable RLS for testing (not recommended for production)

### Error: "File too large"
- The app compresses images to ~50% quality (0.5)
- If still too large, reduce quality further in `SupabaseManager.swift` line 187:
  ```swift
  guard let imageData = image.jpegData(compressionQuality: 0.3) else {
  ```

### Can't See Uploaded Files?
- Make sure the bucket is set to **Public**
- Check that you're looking in the `try-on-images/` subfolder
- Verify the upload didn't fail silently - check Xcode console for errors

## Security Notes

- **Public Bucket**: Anyone with the URL can view images
- **For Production**: Consider making the bucket private and generating signed URLs
- **User Privacy**: Consider adding auto-delete policies for old images
- **Authentication**: Current setup requires Clerk authentication to upload

## Need Help?

- Supabase Storage Docs: https://supabase.com/docs/guides/storage
- Your Project URL: https://pdhmakamlgsosiubivzk.supabase.co
