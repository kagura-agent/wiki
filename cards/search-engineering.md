---
title: Search Engineering
created: 2026-06-04
tags: [search, wiki, idf]
last_verified: 2026-06-04
---

Search engineering covers the design and optimization of the wiki's search system. A key improvement applied IDF (inverse document frequency) weighting from Metatron's three-tier retrieval architecture, where rare terms contribute up to 9.5x more to ranking than ubiquitous terms. The recall-frequency boost is capped at +1.5 so it cannot override IDF-weighted term relevance, preserving relevance geometry.
