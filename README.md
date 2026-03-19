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

Phase 1 and Phase 2 backend foundations are implemented:

- shared contracts package with generated JSON Schema and OpenAPI artifacts
- Fastify `POST /v1/turns` intake path with contract validation
- deterministic safety gateway decisions, routing, clarification tracking, and idempotency handling
- deterministic simulation service with revision assembly, event emission, and outbox job references
- PostgreSQL schema and repository support for turn requests, revisions, clarification state, event logs, and outbox rows
- backend tests covering replay safety, clarification loops, authoritative commits, resource validation, and policy handling
- Flutter shell remains scaffolded for later delivery phases

## Vision

Nexus Tales aims to combine the creativity of language models with the reliability of deterministic systems.
