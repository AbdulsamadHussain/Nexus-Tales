# Nexus Tales

Nexus Tales is a production-grade AI narrative RPG that combines deterministic game simulation with AI-driven storytelling.

Unlike traditional AI chat games, Nexus Tales enforces strict state authority where all gameplay outcomes are controlled by a backend simulation engine. AI models assist with narration, parsing, and summaries, but never control canonical game state.

## Core Principles

- Code owns truth; AI assists but never decides state.
- One turn equals one authoritative revision.
- Deterministic simulation preserves fairness and consistency.
- AI improves presentation quality, not logic ownership.

## Architecture Overview

Player Input
-> Safety and Policy Gateway
-> Deterministic Router
-> Simulation Engine
-> Revision Commit
-> AI Narration and UI Rendering

## Tech Stack

- Frontend: Flutter
- Backend: Node.js + TypeScript + Fastify
- Contracts: Shared Zod 4 package with generated JSON Schema and OpenAPI
- Database: PostgreSQL + Drizzle ORM
- Jobs: pg-boss
- Infrastructure: Supabase Auth and Storage boundaries reserved for identity and media only

## Status

Phase 0 scaffold is in place:

- npm workspaces monorepo
- shared contracts package
- mocked authoritative Fastify turn endpoint
- initial Drizzle PostgreSQL schema
- Flutter shell
- CI check for single contract authority

## Vision

Nexus Tales aims to combine the creativity of language models with the reliability of deterministic systems.
