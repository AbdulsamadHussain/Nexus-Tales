CREATE TABLE "advisory_lock_audit" (
	"id" text PRIMARY KEY NOT NULL,
	"run_id" text NOT NULL,
	"save_slot_id" text NOT NULL,
	"lock_key" bigint NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "campaigns" (
	"id" text PRIMARY KEY NOT NULL,
	"slug" text NOT NULL,
	"display_name" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "campaigns_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "checkpoints" (
	"id" text PRIMARY KEY NOT NULL,
	"revision_id" text NOT NULL,
	"checkpoint_type" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "clarification_state" (
	"id" text PRIMARY KEY NOT NULL,
	"run_id" text NOT NULL,
	"save_slot_id" text NOT NULL,
	"scene_fingerprint" text NOT NULL,
	"last_target_fingerprint" text,
	"last_route_category" text,
	"last_input_fingerprint" text,
	"last_session_id" text NOT NULL,
	"ambiguity_count" integer DEFAULT 0 NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "event_logs" (
	"id" text PRIMARY KEY NOT NULL,
	"revision_id" text NOT NULL,
	"event_type" text NOT NULL,
	"payload" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "job_records" (
	"id" text PRIMARY KEY NOT NULL,
	"revision_id" text,
	"job_type" text NOT NULL,
	"uniqueness_key" text NOT NULL,
	"status" text NOT NULL,
	"payload" jsonb NOT NULL,
	"retry_count" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "migration_records" (
	"id" text PRIMARY KEY NOT NULL,
	"revision_id" text,
	"from_schema_version" integer NOT NULL,
	"to_schema_version" integer NOT NULL,
	"status" text NOT NULL,
	"debug_bundle" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "outbox_events" (
	"id" text PRIMARY KEY NOT NULL,
	"revision_id" text,
	"job_type" text NOT NULL,
	"uniqueness_key" text NOT NULL,
	"payload" jsonb NOT NULL,
	"published_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "revisions" (
	"id" text PRIMARY KEY NOT NULL,
	"run_id" text NOT NULL,
	"save_slot_id" text NOT NULL,
	"previous_revision_id" text,
	"ruleset_version" text NOT NULL,
	"schema_version" integer NOT NULL,
	"canonical_state_pointer" text NOT NULL,
	"action_packet" jsonb NOT NULL,
	"simulation_result" jsonb NOT NULL,
	"autosave_eligible" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "runs" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"campaign_id" text NOT NULL,
	"active_revision_id" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "save_slots" (
	"id" text PRIMARY KEY NOT NULL,
	"run_id" text NOT NULL,
	"slot_type" text NOT NULL,
	"display_name" text NOT NULL,
	"is_protected" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "turn_requests" (
	"id" text PRIMARY KEY NOT NULL,
	"player_id" text NOT NULL,
	"run_id" text NOT NULL,
	"save_slot_id" text NOT NULL,
	"client_turn_id" text NOT NULL,
	"request_hash" text NOT NULL,
	"revision_id" text,
	"status" text NOT NULL,
	"response_payload" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" text PRIMARY KEY NOT NULL,
	"auth_subject" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_auth_subject_unique" UNIQUE("auth_subject")
);
--> statement-breakpoint
ALTER TABLE "advisory_lock_audit" ADD CONSTRAINT "advisory_lock_audit_run_id_runs_id_fk" FOREIGN KEY ("run_id") REFERENCES "public"."runs"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "advisory_lock_audit" ADD CONSTRAINT "advisory_lock_audit_save_slot_id_save_slots_id_fk" FOREIGN KEY ("save_slot_id") REFERENCES "public"."save_slots"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "checkpoints" ADD CONSTRAINT "checkpoints_revision_id_revisions_id_fk" FOREIGN KEY ("revision_id") REFERENCES "public"."revisions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "clarification_state" ADD CONSTRAINT "clarification_state_run_id_runs_id_fk" FOREIGN KEY ("run_id") REFERENCES "public"."runs"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "clarification_state" ADD CONSTRAINT "clarification_state_save_slot_id_save_slots_id_fk" FOREIGN KEY ("save_slot_id") REFERENCES "public"."save_slots"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "event_logs" ADD CONSTRAINT "event_logs_revision_id_revisions_id_fk" FOREIGN KEY ("revision_id") REFERENCES "public"."revisions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "job_records" ADD CONSTRAINT "job_records_revision_id_revisions_id_fk" FOREIGN KEY ("revision_id") REFERENCES "public"."revisions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "outbox_events" ADD CONSTRAINT "outbox_events_revision_id_revisions_id_fk" FOREIGN KEY ("revision_id") REFERENCES "public"."revisions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "revisions" ADD CONSTRAINT "revisions_run_id_runs_id_fk" FOREIGN KEY ("run_id") REFERENCES "public"."runs"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "revisions" ADD CONSTRAINT "revisions_save_slot_id_save_slots_id_fk" FOREIGN KEY ("save_slot_id") REFERENCES "public"."save_slots"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "runs" ADD CONSTRAINT "runs_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "runs" ADD CONSTRAINT "runs_campaign_id_campaigns_id_fk" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "save_slots" ADD CONSTRAINT "save_slots_run_id_runs_id_fk" FOREIGN KEY ("run_id") REFERENCES "public"."runs"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "turn_requests" ADD CONSTRAINT "turn_requests_player_id_users_id_fk" FOREIGN KEY ("player_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "turn_requests" ADD CONSTRAINT "turn_requests_run_id_runs_id_fk" FOREIGN KEY ("run_id") REFERENCES "public"."runs"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "turn_requests" ADD CONSTRAINT "turn_requests_save_slot_id_save_slots_id_fk" FOREIGN KEY ("save_slot_id") REFERENCES "public"."save_slots"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "clarification_state_scope_idx" ON "clarification_state" USING btree ("run_id","save_slot_id","scene_fingerprint");--> statement-breakpoint
CREATE UNIQUE INDEX "job_records_uniqueness_key" ON "job_records" USING btree ("uniqueness_key");--> statement-breakpoint
CREATE UNIQUE INDEX "outbox_events_uniqueness_key" ON "outbox_events" USING btree ("uniqueness_key");--> statement-breakpoint
CREATE UNIQUE INDEX "turn_requests_replay_key" ON "turn_requests" USING btree ("player_id","run_id","save_slot_id","client_turn_id");