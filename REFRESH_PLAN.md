# Refresh Plan: Portfolio Crisp Refresh

## Observed issues
- The site currently uses the default Chirpy blog layout, so the landing view feels like a post index rather than a personal portfolio. There is no clear hero statement, CTA, or featured project grid to quickly communicate who you are and what you do.
- Typography and spacing are utilitarian: list cards are dense, metadata and tags visually compete with titles, and long-form text (e.g., the About page) lacks subheadings or breathing room, making scanning harder.
- Navigation and contact affordances rely on the sidebar defaults; focus/hover affordances and contrast are subtle, which makes the experience feel less polished.
- Visual rhythm is inconsistent between sections (sidebar vs. content vs. footers), and there are minimal accent colors to anchor the brand or highlight interactive elements.

## Planned improvements
- Introduce a concise hero strip on the homepage with name, role, and primary CTA(s), followed by a focused grid for featured work/projects to shift the experience toward a portfolio.
- Refine typography scale and spacing for headings, metadata, and body copy to improve readability and hierarchy across the homepage and About content.
- Update card styling for posts/projects with cleaner borders, subtle shadows, and clearer tag chips; enhance hover/focus states for interactive elements while respecting reduced-motion preferences.
- Adjust color accents (links, buttons, tag pills) to create a cohesive palette with better contrast, while keeping the overall theme identity intact.
- Improve responsive behavior for the hero and project grid, ensuring comfortable padding/margins and readable layouts on mobile, tablet, and desktop.

## Out of scope
- No changes to post content, routing/URLs, or metadata structure.
- No new heavy dependencies, animations, or CMS/features beyond light styling and layout tweaks.
- No alteration of the sidebar structure beyond styling adjustments.

## Assumptions
- Custom styling can be layered via the site’s assets without modifying the upstream Chirpy gem.
- Featured work can be represented using existing post metadata or light front-matter additions without restructuring content.
- The refresh should remain compatible with existing Jekyll builds and avoid introducing console errors.
