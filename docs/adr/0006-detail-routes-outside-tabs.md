# 6. Detail pages are top-level routes

Status: accepted

Concepts, people, texts, the reading room, verses and lessons open from any tab (search,
bookmarks, links). go_router asserts when a route belonging to one tab's branch is pushed
from another tab, which a widget test caught. These pages are therefore top-level routes
(`/concept/:id`, `/person/:id`, …) outside the tab branches.
