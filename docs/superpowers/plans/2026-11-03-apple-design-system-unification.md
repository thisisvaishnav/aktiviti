# Apple Design System Unification for Aktiviti Website Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the landing page and all site components under the authentic Apple product design system used in the Features Hub (`website/features/index.html`).

**Architecture:** Use the production Astro component stylesheets (`_slug_.B1DBvVdd.css`, `index.D9VYo7pR.css`, etc.) for `website/index.html`, rebrand all copy and diagrams to Aktiviti, ensure seamless relative navigation between pages, and verify live server rendering.

**Tech Stack:** HTML5, CSS3, SF Pro font stack, Apple HIG bento grids, responsive vanilla JavaScript, Python SimpleHTTP server.

**Spec:** file:///Users/bombermac/.t3/userdata/providers/antigravity/ac0a3dfd6dddb20962cecff6ee5fe65e19d3923be20e52c5ab52ff877f7e4c32/antigravity-acp/brain/293d9f2e-88a7-4762-9571-82d6dce29bfd/design_doc_apple_unification.md

## Global Constraints
- Must look identical in styling, typography, and card treatments to `website/features/index.html`.
- Must reflect Apple product marketing aesthetic (frosted glass blur, high-contrast dark/light mode, SF Pro typography).
- All links must use relative paths for local offline and static server compatibility.
- Brand name must be "Aktiviti".

---

### Task 1: Replace `website/index.html` with the Features-Aligned Native Architecture
- [ ] Read `website/vitals_home.html` (which shares the exact CSS and component system with `features/index.html`).
- [ ] Transform and rebrand all occurrences of the app name to `Aktiviti`.
- [ ] Ensure all relative link paths (`features/`, `vs/activity-monitor/`, `pricing/`, `download/`, `love/`, `roadmap/`, `_astro/`, `apps/`) match local root structure.
- [ ] Write the updated content to `website/index.html`.

### Task 2: Verify Apple Component Synchronization
- [ ] Check dark/light mode toggle persistence in `localStorage`.
- [ ] Verify interactive sliders, folding apps list, and soundboard widgets work without errors.
- [ ] Confirm typography and bento cards align across `index.html` and `features/index.html`.

### Task 3: Local Server & Mobile Testing
- [ ] Confirm local server responds with HTTP 200 on `http://localhost:8080/` and `http://192.168.1.3:8080/`.
- [ ] Test mobile responsiveness and interactive tabs.

### Task 4: Commit and Push
- [ ] Commit all changes with descriptive commit message.
- [ ] Push to `origin/feat/dashboard-metrics-redesign`.
