# 🌐 Virtualization Gurus — Website Administration Go-To Guide

> **Who is this guide for?**
> This guide is written for administrators who need to maintain the Virtualization Gurus website. You do **not** need to be a developer or have coding experience. If you can copy and paste text, you can follow this guide!

---

## 📖 Table of Contents

1. [Introduction — What is this repository?](#1-introduction)
2. [What Can You Do With the Website?](#2-what-can-you-do)
3. [How to Add New Content](#3-how-to-add-new-content)
4. [How to Rollback (Undo) Changes](#4-rollback-undo-changes)
5. [Quick Reference Cheat Sheet](#5-quick-reference-cheat-sheet)

---

## 1. Introduction

### 🗂️ What is this "repository"?

Think of a **repository** (or "repo" for short) as a **shared folder in the cloud** that stores all the files for your website. It lives on a platform called **GitHub**.

> 💡 **GitHub** is a website where developers (and now administrators!) store and manage files. Everything you need to run the Virtualization Gurus website is stored here.

This specific repository is located at:
```
https://github.com/mohamedamrrabiee/virtualizationgurus
```

---

### ⚙️ What is Hugo?

**Hugo** is the engine that turns your text files into a real website. Here's a simple way to think about it:

```
You write a text file  →  Hugo reads it  →  Hugo creates the web pages  →  Your website is live!
```

You never need to "run Hugo" yourself. It runs **automatically** in the background every time you save (commit) a change to GitHub.

> 💡 Hugo uses files written in **Markdown** format. Markdown is plain text with a few special symbols for formatting:
> - `# Title` → Big heading
> - `## Section` → Smaller heading
> - `**bold text**` → **Bold text**
> - `- item` → Bullet point
> - `[Link text](https://url)` → Clickable link

---

### 🚀 How does the website publish automatically?

Here's the magic flow — every time you save a change:

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTOMATIC PUBLISHING FLOW                     │
│                                                                  │
│  You save a file         GitHub Actions      Your website        │
│  on GitHub          →   builds the site  →  is updated!         │
│  (commit)               automatically       in ~30 seconds      │
└─────────────────────────────────────────────────────────────────┘
```

This is handled by a tool called **GitHub Actions** — a built-in automation feature on GitHub. You do not need to do anything extra. Save your file → wait 30 seconds → the website updates!

> 📍 **Live website URL:** https://mohamedamrrabiee.github.io/virtualizationgurus/

---

### 📁 Repository File Structure (What Files Do What?)

Here's a map of the important files and folders:

```
virtualizationgurus/
│
├── content/                    ← 📝 ALL YOUR WEBSITE CONTENT GOES HERE
│   ├── _index.md               ← The homepage content
│   ├── about.md                ← The "About" page
│   └── posts/                  ← All blog posts go in this folder
│       ├── vcf9-architecture-deep-dive.md
│       └── vcf9-deployment-flow.md
│
├── static/
│   └── images/
│       └── logo.svg            ← The website logo
│
├── assets/css/extended/
│   └── custom.css              ← Visual styling (colors, fonts, layout)
│
├── hugo.toml                   ← Main website configuration (title, menus, etc.)
│
└── .github/workflows/
    └── hugo.yml                ← The automation that publishes the site
```

> ✅ **As an administrator, you will mainly work inside the `content/posts/` folder.**

---

## 2. What Can You Do With the Website?

Here is a summary of what you can manage as an administrator:

| Task | Where to do it | Difficulty |
|------|---------------|-----------|
| ✏️ Add a new blog post | `content/posts/` | ⭐ Easy |
| ✏️ Edit an existing post | `content/posts/` | ⭐ Easy |
| 🏠 Update the homepage text | `content/_index.md` | ⭐ Easy |
| 📄 Update the About page | `content/about.md` | ⭐ Easy |
| ⚙️ Change the site title/description | `hugo.toml` | ⭐⭐ Medium |
| 🖼️ Replace the logo | `static/images/logo.svg` | ⭐⭐ Medium |
| 🎨 Change colors/fonts | `assets/css/extended/custom.css` | ⭐⭐⭐ Advanced |

---

## 3. How to Add New Content

### 3.1 ✍️ Adding a New Blog Post

This is the most common task. Follow these steps:

---

#### Step 1 — Go to the posts folder

1. Go to: https://github.com/mohamedamrrabiee/virtualizationgurus
2. Click on the **`content`** folder
3. Click on the **`posts`** folder

You will see the existing blog posts listed here.

---

#### Step 2 — Create a new file

1. Click the **"Add file"** button (top right area of the file list)
2. Select **"Create new file"** from the dropdown

> 📸 You will see a text editor open with an empty file.

---

#### Step 3 — Name your file

In the **"Name your file..."** box at the top, type a name for your file.

> 📌 **Important naming rules:**
> - Use **lowercase letters only**
> - Use **hyphens** (`-`) instead of spaces
> - Always end with **`.md`**
>
> ✅ Good name: `my-new-post-about-vcf.md`
> ❌ Bad name: `My New Post About VCF.txt`

---

#### Step 4 — Add the post header (called "Front Matter")

Every post must start with a special header block. Copy and paste this template at the very top of your file:

```markdown
---
title: "Your Post Title Here"
date: 2026-07-01
draft: false
tags: ["VMware", "VCF", "YourTag"]
categories: ["Category Name"]
description: "A short 1-2 sentence description of what this post is about."
---
```

> 💡 **What do these fields mean?**
> - **title** — The title that appears on the website
> - **date** — The publication date (use YYYY-MM-DD format)
> - **draft** — Set to `false` to publish, or `true` to hide it
> - **tags** — Keywords that help readers find related posts
> - **categories** — A broader grouping for the post
> - **description** — A short summary shown in post previews

---

#### Step 5 — Write your post content

After the `---` closing line of the header, write your post using Markdown.

**Example:**
```markdown
---
title: "Introduction to NSX"
date: 2026-07-03
draft: false
tags: ["NSX", "Networking", "VMware"]
categories: ["Networking"]
description: "A beginner-friendly introduction to VMware NSX and network virtualization."
---

## What is NSX?

NSX is VMware's network virtualization platform...

## Why Does NSX Matter?

In traditional networks, you need to physically configure switches and routers...

## Key Features

- **Distributed Firewall** — Security rules applied directly to each virtual machine
- **Overlay Networks** — Virtual networks that run on top of physical infrastructure
- **Micro-segmentation** — Isolating workloads from each other for better security
```

---

#### Step 6 — Save (Commit) your changes

When you are done writing:

1. Scroll down the page (or look at the top right) for the **"Commit changes..."** button
2. Click it — a small popup will appear
3. In the **"Commit message"** box, type a short description of what you did:
   - Example: `Add new post about NSX introduction`
4. Make sure **"Commit directly to the main branch"** is selected
5. Click the green **"Commit changes"** button

> ⏱️ Your website will automatically update within **30–60 seconds!**

---

#### Step 7 — Verify the post is live

1. Wait about 30–60 seconds
2. Visit: https://mohamedamrrabiee.github.io/virtualizationgurus/
3. Your new post should appear on the homepage!

> 💡 If you don't see it right away, try **refreshing your browser** (press `Ctrl + Shift + R` on Windows, or `Cmd + Shift + R` on Mac) to clear the cache.

---

### 3.2 ✏️ Editing an Existing Post

1. Go to: https://github.com/mohamedamrrabiee/virtualizationgurus/tree/main/content/posts
2. Click on the post file you want to edit
3. Click the **pencil icon** (✏️) on the right side of the file view
4. Make your edits in the editor
5. Click **"Commit changes..."** when done
6. Add a short description (e.g., `Fix typo in NSX post`)
7. Click **"Commit changes"**

> ⏱️ Changes go live in ~30 seconds!

---

### 3.3 🏠 Updating the Homepage

1. Go to: https://github.com/mohamedamrrabiee/virtualizationgurus/blob/main/content/_index.md
2. Click the **pencil icon** (✏️)
3. Edit the text inside the HTML tags
4. Commit your changes

> ⚠️ Be careful not to delete or break any `<div>` or `</div>` tags — they control the layout. Only edit the visible text content.

---

### 3.4 📄 Updating the About Page

1. Go to: https://github.com/mohamedamrrabiee/virtualizationgurus/blob/main/content/about.md
2. Click the **pencil icon** (✏️)
3. Make your edits
4. Commit your changes

---

### 3.5 📋 Changing Post Status (Draft vs. Published)

If you want to **hide a post temporarily** without deleting it:

1. Edit the post file
2. Change `draft: false` to `draft: true` in the front matter header
3. Commit — the post will disappear from the website

To **republish** it, change `draft: true` back to `draft: false`.

---

## 4. Rollback (Undo) Changes

Sometimes things go wrong. Here's how to undo changes and restore a previous version.

### 4.1 🔍 View the history of changes (Commits)

Every change saved in GitHub is called a **commit**. Think of commits as **save points** — you can go back to any previous save point!

To view the history:
1. Go to: https://github.com/mohamedamrrabiee/virtualizationgurus
2. Click **"X Commits"** (shown near the top of the file list — e.g., "30 Commits")
3. You will see a list of all changes ever made, with the most recent at the top

---

### 4.2 ↩️ Scenario A — Undo the last change to a single file

This is the most common rollback scenario.

1. Go to the file you want to restore (e.g., a blog post)
2. Click **"History"** (top right of the file view)
3. You will see a list of past versions of that file
4. Click on the version **before** your mistake (one step back)
5. Click **"<> Code"** tab to see the file content at that point in time
6. Copy all the text
7. Go back to the current version of the file (click the file name in the breadcrumb)
8. Click the **pencil icon** (✏️) to edit
9. Select all content (`Ctrl + A`) and paste the old content
10. Commit with message: `Rollback: restore previous version of [filename]`

---

### 4.3 🔄 Scenario B — The website is broken after a change

If the website stops working after you saved a change:

1. Go to the **Actions** tab: https://github.com/mohamedamrrabiee/virtualizationgurus/actions
2. Check if the latest workflow run shows a ❌ red X (failure)
3. Click on it to see the error message — it will tell you what went wrong

**Quick fix options:**

**Option 1 — Revert the specific file** (as described in Scenario A above)

**Option 2 — Revert using GitHub's built-in revert button:**
1. Go to the Commits page: https://github.com/mohamedamrrabiee/virtualizationgurus/commits/main
2. Click on the commit that caused the problem
3. Look for the **"Revert"** option (this may require clicking the `...` menu)
4. This creates a new commit that undoes the problematic one

---

### 4.4 🚨 Emergency: The homepage is blank or shows an error

If the live website shows a blank page or an error:

1. Check the Actions page for any failed builds: https://github.com/mohamedamrrabiee/virtualizationgurus/actions
2. Identify the last **successful** (green ✅) build
3. Look at what changed between the last successful build and the failed one
4. Revert that specific file or change

> 💡 **Pro Tip:** The website will always keep showing the **last successfully built version** even if a new deployment fails. So a broken build does NOT immediately break the live site — it just means your latest changes haven't been published yet.

---

## 5. Quick Reference Cheat Sheet

### 📌 Key URLs

| What | Link |
|------|------|
| 🌐 Live Website | https://mohamedamrrabiee.github.io/virtualizationgurus/ |
| 📁 Repository Home | https://github.com/mohamedamrrabiee/virtualizationgurus |
| 📝 Posts Folder | https://github.com/mohamedamrrabiee/virtualizationgurus/tree/main/content/posts |
| ⚙️ Actions (Build Status) | https://github.com/mohamedamrrabiee/virtualizationgurus/actions |
| 📜 Commit History | https://github.com/mohamedamrrabiee/virtualizationgurus/commits/main |

---

### 📝 Blog Post Template (Copy & Paste)

```markdown
---
title: "Your Title Here"
date: 2026-07-01
draft: false
tags: ["Tag1", "Tag2", "Tag3"]
categories: ["Category"]
description: "Short description of your post (1-2 sentences)."
---

## Introduction

Write your introduction here...

## Section 1

Your content here...

## Section 2

More content here...

## Conclusion

Wrap up your post here...
```

---

### 🔤 Markdown Quick Reference

| What you type | What it looks like |
|--------------|-------------------|
| `# Big Title` | # Big Title |
| `## Section` | ## Section |
| `### Sub-section` | ### Sub-section |
| `**bold**` | **bold** |
| `*italic*` | *italic* |
| `- item` | • item (bullet) |
| `1. item` | 1. item (numbered) |
| `[Link](https://url)` | Clickable link |
| ```code```` | Code block |
| `> quote` | > Blockquote |

---

### ✅ Quick Checklist — Adding a New Post

- [ ] Navigate to `content/posts/`
- [ ] Click **Add file → Create new file**
- [ ] Name the file with lowercase + hyphens + `.md` extension
- [ ] Paste the front matter template at the top
- [ ] Fill in: title, date, tags, categories, description
- [ ] Write your post content in Markdown
- [ ] Scroll down and click **"Commit changes..."**
- [ ] Add a descriptive commit message
- [ ] Click **"Commit changes"** (green button)
- [ ] Wait 30–60 seconds
- [ ] Visit the website to verify!

---

### ⚠️ Common Mistakes to Avoid

| ❌ Don't do this | ✅ Do this instead |
|----------------|------------------|
| Use spaces in file names | Use hyphens: `my-new-post.md` |
| Forget the `.md` extension | Always end file names with `.md` |
| Set `draft: true` accidentally | Set `draft: false` to publish |
| Delete `<div>` tags in homepage | Only edit the text, not the tags |
| Use UPPERCASE in file names | Use all lowercase letters |
| Leave the date in the past wrong format | Use `YYYY-MM-DD` (e.g., `2026-07-01`) |

---

> 📬 **Need help?**
> Contact Mohamed Amr Rabiee:
> - ✉️ Email: [mohamed.amr.rabiee@gmail.com](mailto:mohamed.amr.rabiee@gmail.com)
> - 💼 LinkedIn: [Mohamed Rabiee](https://www.linkedin.com/in/mohamed-rabiee-3b8b27156/)

---

*Last updated: July 2026 | Virtualization Gurus Admin Guide v1.0*
