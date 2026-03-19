# Nexus Tales

Nexus Tales is a production-grade AI narrative RPG that combines deterministic game simulation with AI-driven storytelling.

Unlike traditional AI chat games, Nexus Tales enforces strict state authority where all gameplay outcomes are controlled by a backend simulation engine. AI models assist with narration, parsing, and summaries, but never control canonical game state.

## Core Principles

- Code owns truth — AI assists but never decides state
- One turn = one authoritative revision
- Deterministic simulation ensures fairness and consistency
- AI enhances immersion, not logic

## Architecture Overview

Player Input  
→ Safety & Policy Gateway  
→ Deterministic Router  
→ Simulation Engine (authoritative)  
→ State Commit (revision system)  
→ AI Narration & UI Rendering  

## Features (Planned)

- Chat-first RPG gameplay
- Deterministic combat and decision system
- Persistent world state with rollback support
- AI-generated narration and scene visuals
- Modular campaign system

## Tech Stack

- Frontend: Flutter
- Backend: Node / Python (TBD)
- AI Integration: Multi-model routing
- Database: Firestore / PostgreSQL (TBD)

## Status

🚧 In active development — production architecture defined, implementation in progress.

---

## Vision

Nexus Tales aims to redefine AI-driven games by combining the creativity of language models with the reliability of deterministic systems.
