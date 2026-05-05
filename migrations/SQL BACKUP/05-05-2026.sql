--
-- PostgreSQL database dump
--

\restrict d8nVYJbCGhjWWyzUg6aVkKbejM4d8KIUm6YTmBZ5kSFwuYqNaMO7xaHa0PgOH6C

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-05-05 10:40:57

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE cmdb_db;
--
-- TOC entry 5418 (class 1262 OID 30423)
-- Name: cmdb_db; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE cmdb_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Indonesian_Indonesia.1252';


\unrestrict d8nVYJbCGhjWWyzUg6aVkKbejM4d8KIUm6YTmBZ5kSFwuYqNaMO7xaHa0PgOH6C
\connect cmdb_db
\restrict d8nVYJbCGhjWWyzUg6aVkKbejM4d8KIUm6YTmBZ5kSFwuYqNaMO7xaHa0PgOH6C

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- TOC entry 897 (class 1247 OID 30425)
-- Name: connection_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.connection_type_enum AS ENUM (
    'depends_on',
    'consumed_by',
    'connects_to',
    'contains',
    'managed_by',
    'data_flow_to',
    'backup_to',
    'backed_up_by',
    'hosted_on',
    'hosting',
    'licensed_by',
    'licensing',
    'part_of',
    'comprised_of',
    'related_to',
    'preceding',
    'succeeding',
    'encrypted_by',
    'encrypting',
    'authenticated_by',
    'authenticating',
    'monitoring',
    'monitored_by',
    'load_balanced_by',
    'load_balancing',
    'failing_over_to',
    'failover_from',
    'replicating_to',
    'replicated_by',
    'proxying_for',
    'proxied_by',
    'routed_through',
    'routing'
);


--
-- TOC entry 269 (class 1255 OID 30491)
-- Name: create_default_external_positions(integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_default_external_positions(p_workspace_id integer, p_service_id integer, p_external_item_ids integer[]) RETURNS TABLE(id integer, external_service_item_id integer, item_position jsonb)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_item_id INTEGER;
  v_index INTEGER := 0;
  v_offset_x INTEGER := 500;
  v_offset_y INTEGER := 100;
BEGIN
  -- Insert positions satu per satu dengan loop yang benar
  FOREACH v_item_id IN ARRAY p_external_item_ids
  LOOP
    INSERT INTO external_item_positions (
      workspace_id,
      service_id,
      external_service_item_id,
      position,
      is_auto_layouted,
      layout_hash
    )
    VALUES (
      p_workspace_id,
      p_service_id,
      v_item_id,
      jsonb_build_object(
        'x', v_offset_x + (v_index % 4) * 200,
        'y', v_offset_y + floor(v_index / 4.0) * 150
      ),
      true,
      md5(p_service_id || '-' || v_item_id || '-' || extract(epoch from now))
    )
    ON CONFLICT (workspace_id, service_id, external_service_item_id)
    DO NOTHING;

    v_index := v_index + 1;
  END LOOP;

  -- Return semua positions setelah loop selesai (hanya sekali!)
  RETURN QUERY
  SELECT
    eip.id,
    eip.external_service_item_id,
    eip.position AS item_position
  FROM external_item_positions eip
  WHERE eip.workspace_id = p_workspace_id
    AND eip.service_id = p_service_id
    AND eip.external_service_item_id = ANY(p_external_item_ids)
  ORDER BY array_position(p_external_item_ids, eip.external_service_item_id);
END;
$$;


--
-- TOC entry 270 (class 1255 OID 30492)
-- Name: ensure_external_item_position(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_external_item_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  target_workspace_id INTEGER;
  target_service_id INTEGER;
BEGIN
  -- Get workspace dan service dari context
  -- Trigger ini akan dipanggil manual melalui API endpoint
  RETURN NEW;
END;
$$;


--
-- TOC entry 271 (class 1255 OID 30493)
-- Name: update_cross_service_connections_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_cross_service_connections_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- TOC entry 272 (class 1255 OID 30494)
-- Name: update_cross_service_edge_handles_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_cross_service_edge_handles_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- TOC entry 273 (class 1255 OID 30495)
-- Name: update_external_item_positions_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_external_item_positions_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- TOC entry 274 (class 1255 OID 30496)
-- Name: update_layanan_service_conn_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_layanan_service_conn_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- TOC entry 275 (class 1255 OID 30497)
-- Name: update_service_to_service_connections_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_service_to_service_connections_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 30498)
-- Name: cmdb_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cmdb_groups (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    color character varying(7) DEFAULT '#e0e7ff'::character varying,
    "position" jsonb,
    created_at timestamp without time zone DEFAULT now(),
    workspace_id integer NOT NULL
);


--
-- TOC entry 220 (class 1259 OID 30508)
-- Name: cmdb_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cmdb_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5419 (class 0 OID 0)
-- Dependencies: 220
-- Name: cmdb_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cmdb_groups_id_seq OWNED BY public.cmdb_groups.id;


--
-- TOC entry 221 (class 1259 OID 30509)
-- Name: cmdb_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cmdb_items (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    type character varying(50),
    description text,
    "position" jsonb DEFAULT '{"x": 0, "y": 0}'::jsonb,
    status character varying(30) DEFAULT 'active'::character varying,
    ip character varying(45),
    category character varying(12),
    location character varying(50),
    group_id integer,
    order_in_group integer,
    env_type character varying(12),
    workspace_id integer NOT NULL,
    storage jsonb,
    alias character varying(255),
    port integer
);


--
-- TOC entry 222 (class 1259 OID 30519)
-- Name: cmdb_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cmdb_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5420 (class 0 OID 0)
-- Dependencies: 222
-- Name: cmdb_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cmdb_items_id_seq OWNED BY public.cmdb_items.id;


--
-- TOC entry 223 (class 1259 OID 30520)
-- Name: connection_type_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connection_type_definitions (
    id integer NOT NULL,
    type_slug public.connection_type_enum NOT NULL,
    label character varying(50) NOT NULL,
    description text,
    icon character varying(50),
    default_direction character varying(20) DEFAULT 'forward'::character varying,
    color character varying(20) DEFAULT '#3b82f6'::character varying,
    show_arrow boolean DEFAULT true,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    propagation character varying(20) DEFAULT 'both'::character varying
);


--
-- TOC entry 224 (class 1259 OID 30534)
-- Name: connection_type_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connection_type_definitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5421 (class 0 OID 0)
-- Dependencies: 224
-- Name: connection_type_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connection_type_definitions_id_seq OWNED BY public.connection_type_definitions.id;


--
-- TOC entry 225 (class 1259 OID 30535)
-- Name: connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connections (
    id integer NOT NULL,
    source_id integer,
    target_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    target_group_id integer,
    source_group_id integer,
    workspace_id integer NOT NULL,
    connection_type public.connection_type_enum DEFAULT 'depends_on'::public.connection_type_enum,
    direction character varying(20) DEFAULT 'forward'::character varying,
    target_service_id integer,
    target_service_item_id integer,
    source_service_id integer,
    source_service_item_id integer,
    CONSTRAINT check_source_exists CHECK ((((source_id IS NOT NULL) AND (source_group_id IS NULL) AND (source_service_id IS NULL) AND (source_service_item_id IS NULL)) OR ((source_group_id IS NOT NULL) AND (source_id IS NULL) AND (source_service_id IS NULL) AND (source_service_item_id IS NULL)) OR ((source_service_id IS NOT NULL) AND (source_id IS NULL) AND (source_group_id IS NULL) AND (source_service_item_id IS NULL)) OR ((source_service_item_id IS NOT NULL) AND (source_id IS NULL) AND (source_group_id IS NULL) AND (source_service_id IS NULL)))),
    CONSTRAINT check_target CHECK ((((target_id IS NOT NULL) AND (target_group_id IS NULL) AND (target_service_id IS NULL) AND (target_service_item_id IS NULL)) OR ((target_id IS NULL) AND (target_group_id IS NOT NULL) AND (target_service_id IS NULL) AND (target_service_item_id IS NULL)) OR ((target_id IS NULL) AND (target_group_id IS NULL) AND (target_service_id IS NOT NULL) AND (target_service_item_id IS NULL)) OR ((target_id IS NULL) AND (target_group_id IS NULL) AND (target_service_id IS NULL) AND (target_service_item_id IS NOT NULL))))
);


--
-- TOC entry 226 (class 1259 OID 30545)
-- Name: connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5422 (class 0 OID 0)
-- Dependencies: 226
-- Name: connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connections_id_seq OWNED BY public.connections.id;


--
-- TOC entry 227 (class 1259 OID 30546)
-- Name: cross_service_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cross_service_connections (
    id integer NOT NULL,
    source_service_item_id integer NOT NULL,
    target_service_item_id integer NOT NULL,
    workspace_id integer NOT NULL,
    connection_type public.connection_type_enum DEFAULT 'connects_to'::public.connection_type_enum,
    direction character varying(20) DEFAULT 'forward'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    propagation_enabled boolean DEFAULT true,
    CONSTRAINT cross_service_not_same CHECK ((source_service_item_id <> target_service_item_id))
);


--
-- TOC entry 228 (class 1259 OID 30559)
-- Name: cross_service_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cross_service_connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5423 (class 0 OID 0)
-- Dependencies: 228
-- Name: cross_service_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cross_service_connections_id_seq OWNED BY public.cross_service_connections.id;


--
-- TOC entry 229 (class 1259 OID 30560)
-- Name: cross_service_edge_handles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cross_service_edge_handles (
    id integer NOT NULL,
    edge_id character varying(255) NOT NULL,
    source_service_id integer NOT NULL,
    target_service_id integer NOT NULL,
    source_handle character varying(50) DEFAULT 'source-right'::character varying NOT NULL,
    target_handle character varying(50) DEFAULT 'target-left'::character varying NOT NULL,
    workspace_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    viewing_service_id integer
);


--
-- TOC entry 230 (class 1259 OID 30574)
-- Name: cross_service_edge_handles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cross_service_edge_handles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5424 (class 0 OID 0)
-- Dependencies: 230
-- Name: cross_service_edge_handles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cross_service_edge_handles_id_seq OWNED BY public.cross_service_edge_handles.id;


--
-- TOC entry 231 (class 1259 OID 30575)
-- Name: edge_handles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.edge_handles (
    id integer NOT NULL,
    edge_id character varying(255) NOT NULL,
    source_handle character varying(50) NOT NULL,
    target_handle character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    workspace_id integer NOT NULL
);


--
-- TOC entry 232 (class 1259 OID 30585)
-- Name: edge_handles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.edge_handles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5425 (class 0 OID 0)
-- Dependencies: 232
-- Name: edge_handles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.edge_handles_id_seq OWNED BY public.edge_handles.id;


--
-- TOC entry 233 (class 1259 OID 30586)
-- Name: external_item_positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_item_positions (
    id integer NOT NULL,
    workspace_id integer NOT NULL,
    service_id integer NOT NULL,
    external_service_item_id integer NOT NULL,
    "position" jsonb DEFAULT '{"x": 0, "y": 0}'::jsonb NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_auto_layouted boolean DEFAULT false,
    layout_hash character varying(255)
);


--
-- TOC entry 234 (class 1259 OID 30600)
-- Name: external_item_positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_item_positions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5426 (class 0 OID 0)
-- Dependencies: 234
-- Name: external_item_positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_item_positions_id_seq OWNED BY public.external_item_positions.id;


--
-- TOC entry 235 (class 1259 OID 30601)
-- Name: service_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_items (
    id integer NOT NULL,
    service_id integer NOT NULL,
    name character varying(100) NOT NULL,
    type character varying(50),
    description text,
    "position" jsonb DEFAULT '{"x": 0, "y": 0}'::jsonb,
    status character varying(30) DEFAULT 'active'::character varying,
    ip character varying(45),
    category character varying(12),
    location character varying(50),
    workspace_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    group_id integer,
    order_in_group integer DEFAULT 0,
    domain character varying(255),
    port integer
);


--
-- TOC entry 236 (class 1259 OID 30615)
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id integer NOT NULL,
    cmdb_item_id integer NOT NULL,
    name character varying(100) NOT NULL,
    status character varying(30) DEFAULT 'active'::character varying,
    icon_type character varying(20) DEFAULT 'preset'::character varying,
    icon_path character varying(255),
    icon_name character varying(50),
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    workspace_id integer NOT NULL,
    "position" jsonb DEFAULT '{"x": 0, "y": 0}'::jsonb,
    width integer DEFAULT 120,
    height integer DEFAULT 80,
    is_expanded boolean DEFAULT false
);


--
-- TOC entry 237 (class 1259 OID 30632)
-- Name: external_items_with_positions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.external_items_with_positions AS
 SELECT eip.id AS position_id,
    eip.workspace_id,
    eip.service_id,
    eip.external_service_item_id,
    eip."position",
    eip.is_auto_layouted,
    eip.layout_hash,
    eip.updated_at,
    si.name AS item_name,
    si.type AS item_type,
    si.status AS item_status,
    s.name AS source_service_name,
    s.id AS source_service_id
   FROM ((public.external_item_positions eip
     JOIN public.service_items si ON ((eip.external_service_item_id = si.id)))
     JOIN public.services s ON ((si.service_id = s.id)));


--
-- TOC entry 238 (class 1259 OID 30637)
-- Name: group_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_connections (
    id integer NOT NULL,
    source_id integer,
    target_id integer,
    created_at timestamp without time zone DEFAULT now(),
    workspace_id integer NOT NULL,
    connection_type public.connection_type_enum DEFAULT 'depends_on'::public.connection_type_enum,
    direction character varying(20) DEFAULT 'forward'::character varying
);


--
-- TOC entry 239 (class 1259 OID 30645)
-- Name: group_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5427 (class 0 OID 0)
-- Dependencies: 239
-- Name: group_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_connections_id_seq OWNED BY public.group_connections.id;


--
-- TOC entry 240 (class 1259 OID 30646)
-- Name: service_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_connections (
    id integer NOT NULL,
    service_id integer NOT NULL,
    source_id integer NOT NULL,
    target_id integer NOT NULL,
    workspace_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    connection_type public.connection_type_enum DEFAULT 'connects_to'::public.connection_type_enum,
    propagation character varying(20) DEFAULT 'source_to_target'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT service_connections_propagation_check CHECK (((propagation)::text = ANY (ARRAY[('source_to_target'::character varying)::text, ('target_to_source'::character varying)::text, ('both'::character varying)::text])))
);


--
-- TOC entry 241 (class 1259 OID 30659)
-- Name: service_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5428 (class 0 OID 0)
-- Dependencies: 241
-- Name: service_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_connections_id_seq OWNED BY public.service_connections.id;


--
-- TOC entry 242 (class 1259 OID 30660)
-- Name: service_edge_handles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_edge_handles (
    id integer NOT NULL,
    edge_id character varying(255) NOT NULL,
    source_handle character varying(50) NOT NULL,
    target_handle character varying(50) NOT NULL,
    service_id integer NOT NULL,
    workspace_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- TOC entry 243 (class 1259 OID 30671)
-- Name: service_edge_handles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_edge_handles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5429 (class 0 OID 0)
-- Dependencies: 243
-- Name: service_edge_handles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_edge_handles_id_seq OWNED BY public.service_edge_handles.id;


--
-- TOC entry 244 (class 1259 OID 30672)
-- Name: service_group_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_group_connections (
    id integer NOT NULL,
    service_id integer NOT NULL,
    source_id integer,
    target_id integer,
    created_at timestamp without time zone DEFAULT now(),
    workspace_id integer NOT NULL,
    source_group_id integer,
    target_group_id integer,
    target_item_id integer,
    CONSTRAINT check_service_group_source CHECK ((((source_id IS NOT NULL) AND (source_group_id IS NULL)) OR ((source_id IS NULL) AND (source_group_id IS NOT NULL)))),
    CONSTRAINT check_sgc_target CHECK ((((target_id IS NOT NULL) AND (target_item_id IS NULL)) OR ((target_id IS NULL) AND (target_item_id IS NOT NULL)) OR ((target_id IS NULL) AND (target_item_id IS NULL))))
);


--
-- TOC entry 245 (class 1259 OID 30681)
-- Name: service_group_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_group_connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5430 (class 0 OID 0)
-- Dependencies: 245
-- Name: service_group_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_group_connections_id_seq OWNED BY public.service_group_connections.id;


--
-- TOC entry 246 (class 1259 OID 30682)
-- Name: service_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_groups (
    id integer NOT NULL,
    service_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    color character varying(7) DEFAULT '#e0e7ff'::character varying,
    "position" jsonb,
    created_at timestamp without time zone DEFAULT now(),
    workspace_id integer NOT NULL
);


--
-- TOC entry 247 (class 1259 OID 30693)
-- Name: service_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5431 (class 0 OID 0)
-- Dependencies: 247
-- Name: service_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_groups_id_seq OWNED BY public.service_groups.id;


--
-- TOC entry 248 (class 1259 OID 30694)
-- Name: service_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5432 (class 0 OID 0)
-- Dependencies: 248
-- Name: service_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_items_id_seq OWNED BY public.service_items.id;


--
-- TOC entry 249 (class 1259 OID 30695)
-- Name: service_to_service_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_to_service_connections (
    id integer NOT NULL,
    cmdb_item_id integer NOT NULL,
    source_service_id integer NOT NULL,
    target_service_id integer NOT NULL,
    connection_type public.connection_type_enum DEFAULT 'connects_to'::public.connection_type_enum,
    direction character varying(20) DEFAULT 'forward'::character varying,
    propagation character varying(20) DEFAULT 'source_to_target'::character varying,
    workspace_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT no_self_service_connection CHECK ((source_service_id <> target_service_id)),
    CONSTRAINT valid_service_direction CHECK (((direction)::text = ANY (ARRAY[('forward'::character varying)::text, ('backward'::character varying)::text, ('bidirectional'::character varying)::text]))),
    CONSTRAINT valid_service_propagation CHECK (((propagation)::text = ANY (ARRAY[('source_to_target'::character varying)::text, ('target_to_source'::character varying)::text, ('both'::character varying)::text])))
);


--
-- TOC entry 250 (class 1259 OID 30711)
-- Name: service_to_service_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_to_service_connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5433 (class 0 OID 0)
-- Dependencies: 250
-- Name: service_to_service_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_to_service_connections_id_seq OWNED BY public.service_to_service_connections.id;


--
-- TOC entry 251 (class 1259 OID 30712)
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5434 (class 0 OID 0)
-- Dependencies: 251
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- TOC entry 252 (class 1259 OID 30713)
-- Name: share_access_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.share_access_logs (
    id integer NOT NULL,
    share_link_id integer NOT NULL,
    visitor_ip character varying(45),
    visitor_user_agent text,
    accessed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- TOC entry 253 (class 1259 OID 30721)
-- Name: share_access_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.share_access_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5435 (class 0 OID 0)
-- Dependencies: 253
-- Name: share_access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.share_access_logs_id_seq OWNED BY public.share_access_logs.id;


--
-- TOC entry 254 (class 1259 OID 30722)
-- Name: share_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.share_links (
    id integer NOT NULL,
    token character varying(255) NOT NULL,
    workspace_id integer NOT NULL,
    created_by integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone,
    is_active boolean DEFAULT true,
    access_count integer DEFAULT 0,
    password_hash character varying(255),
    last_accessed_at timestamp without time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    service_id integer,
    cmdb_item_id integer
);


--
-- TOC entry 255 (class 1259 OID 30735)
-- Name: share_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.share_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5436 (class 0 OID 0)
-- Dependencies: 255
-- Name: share_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.share_links_id_seq OWNED BY public.share_links.id;


--
-- TOC entry 256 (class 1259 OID 30736)
-- Name: workspaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspaces (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_default boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- TOC entry 257 (class 1259 OID 30746)
-- Name: workspaces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workspaces_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5437 (class 0 OID 0)
-- Dependencies: 257
-- Name: workspaces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workspaces_id_seq OWNED BY public.workspaces.id;


--
-- TOC entry 4960 (class 2604 OID 30747)
-- Name: cmdb_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_groups ALTER COLUMN id SET DEFAULT nextval('public.cmdb_groups_id_seq'::regclass);


--
-- TOC entry 4963 (class 2604 OID 30748)
-- Name: cmdb_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_items ALTER COLUMN id SET DEFAULT nextval('public.cmdb_items_id_seq'::regclass);


--
-- TOC entry 4966 (class 2604 OID 30749)
-- Name: connection_type_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_type_definitions ALTER COLUMN id SET DEFAULT nextval('public.connection_type_definitions_id_seq'::regclass);


--
-- TOC entry 4973 (class 2604 OID 30750)
-- Name: connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections ALTER COLUMN id SET DEFAULT nextval('public.connections_id_seq'::regclass);


--
-- TOC entry 4977 (class 2604 OID 30751)
-- Name: cross_service_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_service_connections ALTER COLUMN id SET DEFAULT nextval('public.cross_service_connections_id_seq'::regclass);


--
-- TOC entry 4983 (class 2604 OID 30752)
-- Name: cross_service_edge_handles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_service_edge_handles ALTER COLUMN id SET DEFAULT nextval('public.cross_service_edge_handles_id_seq'::regclass);


--
-- TOC entry 4988 (class 2604 OID 30753)
-- Name: edge_handles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edge_handles ALTER COLUMN id SET DEFAULT nextval('public.edge_handles_id_seq'::regclass);


--
-- TOC entry 4991 (class 2604 OID 30754)
-- Name: external_item_positions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_item_positions ALTER COLUMN id SET DEFAULT nextval('public.external_item_positions_id_seq'::regclass);


--
-- TOC entry 5011 (class 2604 OID 30755)
-- Name: group_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections ALTER COLUMN id SET DEFAULT nextval('public.group_connections_id_seq'::regclass);


--
-- TOC entry 5015 (class 2604 OID 30756)
-- Name: service_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections ALTER COLUMN id SET DEFAULT nextval('public.service_connections_id_seq'::regclass);


--
-- TOC entry 5020 (class 2604 OID 30757)
-- Name: service_edge_handles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_edge_handles ALTER COLUMN id SET DEFAULT nextval('public.service_edge_handles_id_seq'::regclass);


--
-- TOC entry 5023 (class 2604 OID 30758)
-- Name: service_group_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections ALTER COLUMN id SET DEFAULT nextval('public.service_group_connections_id_seq'::regclass);


--
-- TOC entry 5025 (class 2604 OID 30759)
-- Name: service_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_groups ALTER COLUMN id SET DEFAULT nextval('public.service_groups_id_seq'::regclass);


--
-- TOC entry 4996 (class 2604 OID 30760)
-- Name: service_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items ALTER COLUMN id SET DEFAULT nextval('public.service_items_id_seq'::regclass);


--
-- TOC entry 5028 (class 2604 OID 30761)
-- Name: service_to_service_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_to_service_connections ALTER COLUMN id SET DEFAULT nextval('public.service_to_service_connections_id_seq'::regclass);


--
-- TOC entry 5002 (class 2604 OID 30762)
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- TOC entry 5034 (class 2604 OID 30763)
-- Name: share_access_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_access_logs ALTER COLUMN id SET DEFAULT nextval('public.share_access_logs_id_seq'::regclass);


--
-- TOC entry 5036 (class 2604 OID 30764)
-- Name: share_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links ALTER COLUMN id SET DEFAULT nextval('public.share_links_id_seq'::regclass);


--
-- TOC entry 5041 (class 2604 OID 30765)
-- Name: workspaces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspaces ALTER COLUMN id SET DEFAULT nextval('public.workspaces_id_seq'::regclass);


--
-- TOC entry 5375 (class 0 OID 30498)
-- Dependencies: 219
-- Data for Name: cmdb_groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (11, 'PLAN MAXIMO DEVELOPMENT', '', '#d6d6d6', '{"x": 562.1020388235285, "y": -3214.420124760768}', '2025-12-18 09:09:24.621683', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (7, 'Dynamics AX Production', 'Dynamic AX Ecosystem', '#d6d6d6', '{"x": -1106.348576575209, "y": -3915.6916477449163}', '2025-12-17 14:37:51.72339', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (18, 'SQL SERVER PRODUCTION', '', '#d6d6d6', '{"x": -1311.0547906510508, "y": -3461.52667906644}', '2026-01-06 06:34:18.687279', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (67, 'Citrix', '', '#c7c7c7', '{"x": -67.25786258575897, "y": -4453.555885803121}', '2026-02-03 09:04:29.376804', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (10, 'Kubernetes Cluster', '', '#cccccc', '{"x": -2045.1829655132747, "y": -3933.954878404761}', '2025-12-17 15:31:56.19422', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (69, 'TPS WEB', '', '#c9c9c9', '{"x": -441.6257580824085, "y": -754.6594731397225}', '2026-02-09 10:33:29.457976', 5) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (68, 'TPS HSSE ENV', '', '#c9c9c9', '{"x": -1173.2280064496329, "y": -751.6330752024941}', '2026-02-09 09:30:01.997017', 5) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (8, 'Reporting Service', '', '#d6d6d6', '{"x": -612.7609237985744, "y": -3692.7323943344245}', '2025-12-17 14:46:00.352563', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (72, 'G1', '', '#e0e7ff', '{"x": 1135.6399561841815, "y": -600.6117143232324}', '2026-03-05 20:13:51.814282', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (82, '12', '', '#e0e7ff', '{"x": -1054.9509040069493, "y": -533.526285965547}', '2026-03-31 08:55:29.011115', 29) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (80, 'Production', 'Production servers', '#10b7a3', '{"x": -131.8169574200092, "y": -217.69866685833372}', '2026-03-30 08:39:14.745865', 29) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (81, 'DM', '', '#e0e7ff', '{"x": -1249.4437242175854, "y": -898.4833938623198}', '2026-03-31 08:42:26.159708', 29) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (74, 'TG1', '', '#ffc2c2', '{"x": -1326.1859327414531, "y": -3240.842664059342}', '2026-03-16 14:07:42.244738', 28) ON CONFLICT DO NOTHING;


--
-- TOC entry 5377 (class 0 OID 30509)
-- Dependencies: 221
-- Data for Name: cmdb_items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (135, 'K8S2 Docker Worker', 'server', '-', '{"x": 290.7773058393324, "y": -3519.9908313640303}', 'active', '192.168.98.250', 'internal', 'CFS', 10, 1, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (136, 'TPSAXAPP03', 'server', '-', '{"x": -633.8460950649908, "y": -3817.0973967099944}', 'active', '192.168.146.21', 'internal', 'Dermaga', 7, 2, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (50, 'TPSEC', 'server', '-', '{"x": 830.6733657119155, "y": -3921.9524732356895}', 'active', '192.168.46.45', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (10, 'TPSAXAPP01', 'server', '-', '{"x": -985.2655728233144, "y": -3819.5817642261754}', 'active', '192.168.96.33', 'internal', '', 7, 0, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (138, 'TPSPDS02', 'server', '-', '{"x": 1037.2706511417243, "y": -3692.507065320161}', 'active', '192.168.179.223', 'internal', 'CFS', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (66, 'TPSCTXVPX', 'workstation', 'firewall unit number 66', '{"x": -266.9879356101867, "y": -4308.852473623259}', 'active', '192.168.253.66', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (36, 'TPSH2H02', 'server', '-', '{"x": 319.707089619316, "y": -2823.4917036960433}', 'active', '192.168.93.176', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (1, 'TPSBILL01', 'server', '-', '{"x": -168.07231352085836, "y": -2783.8479618060587}', 'active', '192.168.77.185', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (132, 'VB02', 'server', '-', '{"x": 601.8675150627981, "y": -3426.1575137680315}', 'active', '192.168.146.21', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (18, 'TPSWSAPP', 'server', 'Middleware', '{"x": -1237.7774627444228, "y": -2793.3190452177446}', 'active', '192.168.183.174', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (23, 'TPSDBWEB', 'server', 'SQL SERVER', '{"x": 809.2707279253284, "y": -4279.26442790833}', 'active', '192.168.179.223', 'internal', 'Gedung Baru', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (27, 'VB03', 'server', '-', '{"x": 774.6449633345467, "y": -3426.2335571719736}', 'active', '192.168.188.109', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (31, 'TPSVMAXIMO02', 'server', 'CRON & MIF
SERVER', '{"x": -818.9180501334497, "y": -2763.193377865898}', 'active', '192.168.86.220', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (49, 'APPTOS01', 'server', '-', '{"x": 421.3297441385457, "y": -3922.2371186416312}', 'active', '192.168.58.37', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (128, 'TPSMAXIMODEV02', 'server', '-', '{"x": -355.9605747606204, "y": -3070.8656367386466}', 'active', '192.168.155.574', 'internal', '', 11, 1, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (16, 'TPSAXDB02', 'database', '-', '{"x": -796.1677410989014, "y": -3627.1646755004967}', 'active', '192.168.130.170', 'internal', '', 18, 1, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (5, 'VB04', 'server', '-', '{"x": 946.9886862345692, "y": -3427.557805452265}', 'active', '192.168.73.187', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (41, 'VB05', 'server', '-', '{"x": 1113.501997220478, "y": -3428.1028066015647}', 'active', '192.168.180.250', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (14, 'TPSADBX', 'server', 'SQL SERVER DEVELOPMENT', '{"x": -782.4216315725849, "y": -2961.7506473913836}', 'active', '192.168.110.175', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (71, 'TPSISO', 'server', 'ISO', '{"x": 1540.5793749131776, "y": -4243.073741547727}', 'active', '192.168.68.98', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (12, 'TPSAXDB01', 'database', '-', '{"x": -983.8321581457112, "y": -3628.4480952765803}', 'active', '192.168.167.102', 'internal', '', 18, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (85, 'TPSSQL', 'server', 'SQL SERVER', '{"x": 1467.9340769464814, "y": -3981.5479154804157}', 'active', '192.168.40.63', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (141, 'TPSAXRS01', 'server', 'Server report dynamic ax', '{"x": 400.3585509014064, "y": -2529.6870539060938}', 'active', '172.19.155.95', 'internal', 'Gedung Baru', NULL, 1, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (55, 'APPTOS02', 'server', 'server unit number 55', '{"x": 601.754514915179, "y": -3922.343965304101}', 'active', '192.168.236.220', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (90, 'VB01', 'server', '-', '{"x": 423.90972721755855, "y": -3425.1865200295742}', 'active', '192.168.180.102', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (137, 'TPSAV01', 'workstation', 'KASPERSKY', '{"x": 1361.6239678319773, "y": -4244.77501134421}', 'active', '192.168.179.223', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (13, 'TPSVDBMAXIMO', 'database', 'DB2 PRODUCTION', '{"x": -620.0215819362691, "y": -2762.554072482375}', 'active', '192.168.207.179', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (37, 'DBTOS2', 'server', '-', '{"x": 216.131182684355, "y": -3921.5595223486093}', 'active', '192.168.43.35', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (44, 'DBMAXIMO01', 'database', 'DB2 DEVELOPMENT', '{"x": -413.5441521468426, "y": -2763.5404198652727}', 'active', '192.168.165.88', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (45, 'TPSAXRS01', 'server', '-', '{"x": -516.4313210842436, "y": -3626.0287793079924}', 'active', '192.168.202.113', 'internal', '', 8, 0, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (24, 'TPSAXAPPX', 'server', 'DYNAMICS AX DEVELOPMENT', '{"x": -990.4117699402774, "y": -2961.6677303339466}', 'active', '192.168.225.157', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (25, 'TPSMAXIMODEV01', 'server', '', '{"x": -559.1207477387995, "y": -3071.9317725491674}', 'active', '192.168.244.44', 'internal', '', 11, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (11, 'TPSEDI01', 'server', 'switch unit number 11', '{"x": -660.3713143976054, "y": -4275.317932449176}', 'active', '192.168.50.150', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (15, 'VB06', 'server', '-', '{"x": 1282.3265154747246, "y": -3428.4316344987133}', 'active', '192.168.37.127', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (4, 'TPSEDI02', 'server', '-', '{"x": -467.04844233454355, "y": -4305.985620577113}', 'active', '192.168.75.216', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (53, 'TPSSW', 'server', 'IT HELPDESK', '{"x": 1182.3276693001278, "y": -4246.961569573647}', 'active', '192.168.242.234', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (17, 'TPSSHARE', 'server', 'DOCUMENT MANAGEMENT', '{"x": 1035.6515048468602, "y": -3977.0907431931632}', 'active', '192.168.204.38', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (6, 'TPSBILL02', 'server', '-', '{"x": 43.57393724479401, "y": -2756.91724181054}', 'active', '192.168.224.107', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (139, 'TPSAXDB01', 'database', 'Server Database Dynamic AX 01', '{"x": 602.6528152408985, "y": -2794.904273653363}', 'active', '172.19.155.51', 'eksternal', 'Gedung Baru', NULL, 0, 'virtual', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (63, 'TPSWEB01', 'server', 'database unit number 63', '{"x": -1071.2582081555204, "y": -4232.043182017056}', 'active', '192.168.230.47', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (88, 'TPSAXAPP02', 'server', 'AOS', '{"x": -806.6481598942341, "y": -3816.46406523591}', 'active', '192.168.112.169', 'internal', '', 7, 1, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (140, 'TPSAXAPP01', 'server', 'Server Aplikasi Dynamic AX 01', '{"x": 796.3293777368938, "y": -2530.8847419079075}', 'active', '172.19.155.45', 'internal', 'Gedung Baru', NULL, 2, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (75, 'K8S1 MASTER', 'server', 'server unit number 75', '{"x": 118.73989481127835, "y": -3551.731544182194}', 'active', '192.168.103.150', 'eksternal', 'Dermaga', 10, 0, 'virtual', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (46, 'TPSWEB02', 'server', '-', '{"x": -857.0615131435643, "y": -4201.53351230324}', 'active', '192.168.26.192', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (214, 'WT2 Server2', 'server', '', '{"x": 840.9529491886992, "y": -271.1070056083974}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (82, 'TPSVMAXIMO01', 'server', ' UI & REPORT
SERVER', '{"x": -1015.1388198670294, "y": -2763.5738767312414}', 'active', '192.168.149.148', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (83, 'K8S4 Docker Worker', 'server', 'server unit number 83', '{"x": 721.6838646820923, "y": -3520.0279101374103}', 'active', '192.168.9.139', 'internal', '', 10, 3, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (92, 'K8S3 Docker Worker', 'server', 'firewall unit number 92', '{"x": 506.17967744726235, "y": -3520.4456506338133}', 'active', '192.168.106.144', 'eksternal', '', 10, 2, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (84, 'TPSPROXY', 'switch', 'Proxy', '{"x": 998.5144089990332, "y": -4246.964535615645}', 'active', '192.168.223.27', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (51, 'TPSAXRS02', 'server', 'workstation unit number 51', '{"x": -352.5223118995233, "y": -3627.8256747523874}', 'active', '192.168.41.27', 'internal', '', 8, 1, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (52, 'TPSH2H01', 'server', '-', '{"x": 134.9209778421486, "y": -2940.037697074275}', 'active', '192.168.82.230', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (97, 'TPSDMAX', 'server', 'AX COA LAMA', '{"x": 1722.4787518783096, "y": -4243.841718368561}', 'active', '192.168.139.14', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (20, 'TPSPDS01', 'server', 'database unit number 20', '{"x": 1468.6742982571534, "y": -3758.229494435301}', 'active', '192.168.213.91', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (99, 'TPSGATE', 'server', 'GATE SECURITY
PRODUCTION', '{"x": -156.27291906908306, "y": -3925.980601626821}', 'active', '192.168.22.219', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (133, 'TPSPDS03', 'server', '', '{"x": 862.502930128333, "y": -3707.5785828325515}', 'active', '192.168.155.57', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (59, 'TPSCTXAPP01', 'server', 'server unit number 59', '{"x": -13.02124977071864, "y": -4329.210867229895}', 'active', '192.168.140.135', 'internal', '', 67, 1, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (9, 'TPSCTXAPP02', 'server', '-', '{"x": 198.4361584395415, "y": -4300.68718745754}', 'active', '192.168.145.56', 'internal', '', 67, 2, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (331, 'TPSWEBAPP', 'server', '', '{"x": -138.80535743459885, "y": -616.8526728761374}', 'active', '', 'internal', '', 69, 0, 'fisik', 5, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (332, 'TPWEBDB', 'server', '', '{"x": 64.41351753240775, "y": -709.9946572360154}', 'active', '', 'internal', '', 69, 0, 'fisik', 5, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (328, 'TPSAPP05', 'server', '', '{"x": -523.7771053263082, "y": -626.1473841692055}', 'active', '', 'internal', '', 68, 1, 'fisik', 5, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (327, 'TPSHSSE', 'server', '', '{"x": -852.8556158421036, "y": -419.17076559481484}', 'active', '', 'internal', '', 68, 0, 'fisik', 5, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (329, 'TPSGATE', 'server', '', '{"x": -361.11988776659945, "y": -662.7595987608004}', 'active', '', 'internal', '', 68, 3, 'fisik', 5, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (330, 'TPSAPP02', 'server', '', '{"x": -321.95328737491957, "y": -468.8371626751658}', 'active', '', 'internal', '', 68, 2, 'fisik', 5, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (337, 'WT2 2', 'server', '', '{"x": 2178.2472876105767, "y": -616.5783623931675}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (340, 'WT2 5', 'server', '', '{"x": 2926.050259788641, "y": -442.86137653936663}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (336, 'WT2 1', 'database', '', '{"x": 2613.4947071350234, "y": -322.80084190979085}', 'maintenance', '', 'internal', '', NULL, 0, 'fisik', 10, '{"unit": "GB", "used": 230, "total": 512}', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (21, 'TPSAXAPP', 'server', '[AOS BALANCER]', '{"x": -1480.1713511433175, "y": -3579.782908336422}', 'active', '192.168.0.223', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (29, 'TPSESS', 'server', 'switch unit number 29', '{"x": -1327.2099106185447, "y": -4163.7928791032755}', 'active', '192.168.180.180', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (341, 'WT2 6', 'database', '', '{"x": 2861.5858137859786, "y": -156.0803079490524}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (339, 'WT2 4', 'server', '', '{"x": 2671.3887895625544, "y": -600.5375116496798}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (338, 'WT 3', 'server', '', '{"x": 2408.6735063954106, "y": -481.5590226702338}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (213, 'WT2 Server1', 'server', '', '{"x": 874.613108128633, "y": -554.9391560181423}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (212, 'WT2 DB2', 'database', '', '{"x": 1170.4328024774354, "y": -262.86241023468915}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (100, 'DBTOS1', 'server', '', '{"x": 23.87526764309594, "y": -3921.5743104619087}', 'maintenance', '192.168.195.138', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (211, 'WT2 DB1', 'database', '', '{"x": 1166.7772220507945, "y": -100.94863276582737}', 'inactive', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (365, 'WT2 ITEM3', 'server', '', '{"x": 415.9950434170354, "y": -601.257028834394}', 'active', '', 'internal', '', 72, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (366, 'WT2 TEST3', 'server', '', '{"x": 617.380206914579, "y": -738.9898783083291}', 'active', '', 'internal', '', 72, 0, 'fisik', 10, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (335, 'WST1 01', 'server', '', '{"x": -950.7924247490752, "y": -1139.6594731397229}', 'active', '', 'internal', '', NULL, 0, 'fisik', 5, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (342, 'Test 1222', 'server', '', '{"x": -704.7099685608412, "y": -933.7409058860917}', 'active', '', 'internal', '', NULL, 0, 'fisik', 5, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (57, 'TPSBI', 'server', 'DASHBOARD BI', '{"x": -1242.378183621784, "y": -4453.43281107137}', 'active', '192.168.213.63', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (460, 'SWITH IMP TEST1', 'switch', NULL, '{"x": -32.28927359014449, "y": 425.48371749034806}', 'active', NULL, NULL, NULL, 82, 2, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (480, 'SWITCH IMP TEST3', 'switch', NULL, '{"x": -410.5647968931357, "y": -341.8051585785086}', 'active', NULL, NULL, NULL, 82, 3, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (449, 'DB IMP TEST2', 'database', NULL, '{"x": -669.0402594947933, "y": 229.93623109022832}', 'active', NULL, NULL, NULL, 81, 0, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (452, 'DB IMP TEST5', 'database', '', '{"x": 77.99048479088094, "y": -190.50589652868555}', 'active', '', 'internal', '', 80, NULL, 'fisik', 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (455, 'SERVER IMP TEST3', 'server', NULL, '{"x": -343.64047629878286, "y": -350.62565877790047}', 'active', NULL, NULL, NULL, 80, 4, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (131, 'Bank Server', 'server', '-', '{"x": 160.04077904331456, "y": -3262.523961893584}', 'active', '192.168.146.212', 'eksternal', 'Gedung Baru', NULL, NULL, 'fisik', 1, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (393, 'TPSAPP05', 'server', '', '{"x": 913.7894494522857, "y": -3839.856891037471}', 'active', '172.19.155.51', 'internal', '', NULL, NULL, 'fisik', 27, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (395, 'TPSHSSE', 'server', '', '{"x": 475.31076723572005, "y": -3554.0526550789036}', 'active', '172.19.154.42', 'internal', '', NULL, 0, 'fisik', 27, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (397, 'TPSGATE', 'server', '', '{"x": 694.3437878043158, "y": -3841.6964035281558}', 'active', '', 'internal', '', NULL, NULL, 'fisik', 27, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (394, 'TPSDEV', 'server', '', '{"x": 475.9358245539081, "y": -3877.2403550644294}', 'active', '172.19.154.95', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'my.tps.co.id', 8333) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (392, 'TPSAPP02', 'database', '', '{"x": 1153.694814176246, "y": -3840.119099755678}', 'active', '172.19.155.50', 'internal', '', NULL, NULL, 'fisik', 27, NULL, NULL, 5432) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (453, 'SERVER IMP TEST1', 'server', NULL, '{"x": -345.64607641305287, "y": -157.24671287460774}', 'active', NULL, NULL, NULL, 80, 1, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (457, 'SERVER IMP TEST5', 'server', NULL, '{"x": -41.792817054899274, "y": -351.1509777496307}', 'active', NULL, NULL, NULL, 80, 3, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (456, 'SERVER IMP TEST4', 'server', NULL, '{"x": -435.4144989684903, "y": -518.4637212882027}', 'active', NULL, NULL, NULL, 80, 5, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (450, 'DB IMP TEST3', 'database', '', '{"x": -350.0964550793153, "y": 31.152650663837363}', 'active', '', 'internal', '', 80, 0, 'fisik', 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (470, 'SWITCH IMP TEST2', 'switch', NULL, '{"x": -64.72832686763456, "y": 377.7780531729221}', 'active', NULL, NULL, NULL, 82, 1, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (451, 'DB IMP TEST4', 'database', NULL, '{"x": -659.5461183400998, "y": 14.834595554208278}', 'active', NULL, NULL, NULL, 82, 0, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (448, 'DB IMP TEST1', 'database', NULL, '{"x": -718.9266633805206, "y": -373.21531218512655}', 'active', NULL, NULL, NULL, 81, 2, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (454, 'SERVER IMP TEST2', 'server', NULL, '{"x": -1313.1209007095686, "y": -1085.8469217542872}', 'active', NULL, NULL, NULL, 81, 1, NULL, 29, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (398, 'TGI1', 'server', '', '{"x": -236.1768174037234, "y": -527.638870815729}', 'active', '', 'internal', '', 74, 1, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (404, 'WSTI0', 'server', '', '{"x": -41.85453909171808, "y": -926.0911142875269}', 'active', '', 'internal', '', 74, 0, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (399, 'TGI2', 'server', '', '{"x": 159.87210783496738, "y": -817.4361367431829}', 'active', '', 'internal', '', 74, 3, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (401, 'TGI4', 'server', '', '{"x": 256.6996635334114, "y": -1703.594288430948}', 'active', '', 'internal', '', 74, 2, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (403, 'SS', 'server', '', '{"x": -633.028583038733, "y": -3186.879932307686}', 'active', '', 'internal', '', NULL, NULL, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (478, 'CMDBITEMWST5 1', 'server', '', '{"x": -1.1010861764716537, "y": -3396.0867914274345}', 'active', '', 'internal', '', NULL, 0, 'fisik', 33, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (479, 'CMDBITEMWST5 2', 'server', '', '{"x": 514.8624554901952, "y": -3229.4201247607675}', 'active', '', 'internal', '', NULL, 0, 'fisik', 33, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (402, 'TGI5', 'server', '', '{"x": -214.368182152045, "y": -3369.7757338119986}', 'active', '', 'internal', '', NULL, NULL, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (465, 'TPSAPP02', 'server', '', '{"x": 1286.7937266777265, "y": -4049.7154304612304}', 'active', '', 'internal', '', NULL, 0, 'fisik', 30, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (473, 'asdasdasdr4', 'server', '', '{"x": -787.4794325160332, "y": -3507.258825060507}', 'active', '', 'internal', '', NULL, 0, 'fisik', 12, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (472, 'asdasdasd', 'server', '', '{"x": -569.2763075160332, "y": -3321.4254917271737}', 'active', '', 'internal', '', NULL, 0, 'fisik', 12, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (462, 'TPSAPP05', 'server', '', '{"x": 914.7124068380465, "y": -4050.1749787906356}', 'active', '', 'internal', '', NULL, 0, 'fisik', 30, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (463, 'TPSWEB102', 'server', '', '{"x": 1001.1631564014813, "y": -3608.52910516079}', 'active', '', 'internal', '', NULL, 0, 'fisik', 30, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (464, 'TPSVDEV01', 'server', '', '{"x": 1352.5452758439646, "y": -3829.7582366782017}', 'active', '', 'internal', '', NULL, 0, 'fisik', 30, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (482, 'api.tps.co.di/tjiwi', 'web_application', '', '{"x": 682.9430793116326, "y": -4217.380055967469}', 'active', '', 'internal', '', NULL, 0, 'fisik', 30, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (400, 'TGI3', 'server', '', '{"x": -1323.6785861481555, "y": -3601.6083650573937}', 'active', '', 'internal', '', NULL, NULL, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (467, 'WST01', 'server', '', '{"x": -583.438122903201, "y": -3461.7374102234617}', 'active', '', 'internal', '', NULL, 0, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (471, 'api111', 'api_service', '', '{"x": -860.3781861717418, "y": -3432.625919246017}', 'active', '', 'internal', '', NULL, 0, 'fisik', 28, NULL, NULL, NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 5379 (class 0 OID 30520)
-- Dependencies: 223
-- Data for Name: connection_type_definitions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (1, 'depends_on', 'Depends On', 'Source item depends on target item (jika target mati, source terdampak)', 'arrow-up-right', 'forward', '#3b82f6', true, true, '2026-02-26 14:00:30.177742', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (5, 'managed_by', 'Managed By', 'Source is managed by target', 'shield', 'backward', '#a855f7', true, true, '2026-02-26 14:00:30.177742', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (8, 'backed_up_by', 'Backed Up By', 'Source item is backed up by target item', 'refresh-cw', 'backward', '#14b8a6', true, true, '2026-02-26 14:42:56.963282', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (9, 'hosted_on', 'Hosted On', 'Source item is hosted on target item (VM on physical server)', 'server', 'forward', '#6366f1', true, true, '2026-02-26 14:42:56.972995', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (11, 'licensed_by', 'Licensed By', 'Source item uses license from target item', 'key', 'backward', '#eab308', true, true, '2026-02-26 14:42:56.977598', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (14, 'comprised_of', 'Comprised Of', 'Source item is composed of target item', 'puzzle', 'backward', '#a855f7', true, true, '2026-02-26 14:42:56.983539', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (17, 'succeeding', 'Succeeding', 'Source item succeeds target item in workflow', 'arrow-down', 'backward', '#f97316', true, true, '2026-02-26 14:42:56.988294', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (18, 'encrypted_by', 'Encrypted By', 'Source item is encrypted by target item', 'lock', 'backward', '#be123c', true, true, '2026-02-26 14:42:56.989695', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (20, 'authenticated_by', 'Authenticated By', 'Source item is authenticated by target item', 'shield-check', 'backward', '#059669', true, true, '2026-02-26 14:42:56.992469', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (23, 'monitored_by', 'Monitored By', 'Source item is monitored by target item', 'eye', 'backward', '#ec4899', true, true, '2026-02-26 14:42:56.997289', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (24, 'load_balanced_by', 'Load Balanced By', 'Source item is load balanced by target item', 'scale', 'backward', '#8b5cf6', true, true, '2026-02-26 14:42:56.999077', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (27, 'failover_from', 'Failover From', 'Source item is failover source for target item', 'zap', 'backward', '#ef4444', true, true, '2026-02-26 14:42:57.004301', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (29, 'replicated_by', 'Replicated By', 'Source item is replicated by target item', 'database', 'backward', '#06b6d4', true, true, '2026-02-26 14:42:57.006931', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (31, 'proxied_by', 'Proxied By', 'Source item is proxied by target item', 'workflow', 'backward', '#f59e0b', true, true, '2026-02-26 14:42:57.00959', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (33, 'routing', 'Routing', 'Source item routes target item', 'route', 'backward', '#10b981', true, true, '2026-02-26 14:42:57.012347', 'target_to_source') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (4, 'contains', 'Contains', 'Source contains target (parent-child relationship)', 'layers', 'forward', '#10b981', true, true, '2026-02-26 14:00:30.177742', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (6, 'data_flow_to', 'Data Flow To', 'Data flows from source to target', 'trending-up', 'forward', '#06b6d4', true, true, '2026-02-26 14:00:30.177742', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (7, 'backup_to', 'Backup To', 'Source backs up to target', 'refresh-cw', 'forward', '#14b8a6', true, true, '2026-02-26 14:00:30.177742', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (10, 'hosting', 'Hosting', 'Source item hosts target item', 'server', 'backward', '#6366f1', true, true, '2026-02-26 14:42:56.975285', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (12, 'licensing', 'Licensing', 'Source item provides license to target item', 'key', 'forward', '#eab308', true, true, '2026-02-26 14:42:56.979709', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (13, 'part_of', 'Part Of', 'Source item is part of target item (component relationship)', 'puzzle', 'forward', '#a855f7', true, true, '2026-02-26 14:42:56.982333', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (16, 'preceding', 'Preceding', 'Source item precedes target item in workflow', 'arrow-up', 'forward', '#f97316', true, true, '2026-02-26 14:42:56.986843', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (19, 'encrypting', 'Encrypting', 'Source item encrypts target item', 'lock', 'forward', '#be123c', true, true, '2026-02-26 14:42:56.991096', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (21, 'authenticating', 'Authenticating', 'Source item authenticates target item', 'shield-check', 'forward', '#059669', true, true, '2026-02-26 14:42:56.993744', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (2, 'consumed_by', 'Consumed By', 'Source item is consumed by target item (resource usage)', 'arrow-down-right', 'backward', '#f59e0b', true, true, '2026-02-26 14:00:30.177742', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (22, 'monitoring', 'Monitoring', 'Source item monitors target item', 'eye', 'forward', '#ec4899', true, true, '2026-02-26 14:42:56.995511', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (25, 'load_balancing', 'Load Balancing', 'Source item load balances target item', 'scale', 'forward', '#8b5cf6', true, true, '2026-02-26 14:42:57.000362', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (26, 'failing_over_to', 'Failing Over To', 'Source item fails over to target item', 'zap', 'forward', '#ef4444', true, true, '2026-02-26 14:42:57.00192', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (28, 'replicating_to', 'Replicating To', 'Source item replicates data to target item', 'database', 'forward', '#06b6d4', true, true, '2026-02-26 14:42:57.005574', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (30, 'proxying_for', 'Proxying For', 'Source item proxies requests for target item', 'workflow', 'forward', '#f59e0b', true, true, '2026-02-26 14:42:57.008432', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (32, 'routed_through', 'Routed Through', 'Source item is routed through target item', 'route', 'forward', '#10b981', true, true, '2026-02-26 14:42:57.011061', 'source_to_target') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (3, 'connects_to', 'Connects To', 'Network connection between items', 'link', 'bidirectional', '#8b5cf6', true, true, '2026-02-26 14:00:30.177742', 'both') ON CONFLICT DO NOTHING;
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at, propagation) VALUES (15, 'related_to', 'Related To', 'Source item is related to target item (general relationship)', 'link', 'bidirectional', '#94a3b8', true, true, '2026-02-26 14:42:56.985066', 'both') ON CONFLICT DO NOTHING;


--
-- TOC entry 5381 (class 0 OID 30535)
-- Dependencies: 225
-- Data for Name: connections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (105, 75, 92, '2025-12-18 15:57:03.325009', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (106, 75, 83, '2025-12-18 15:57:03.337364', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (107, 10, 88, '2025-12-18 15:58:25.348392', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (108, 10, 136, '2025-12-18 15:58:25.359345', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (109, 12, 16, '2025-12-18 15:59:20.812268', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (111, 45, 51, '2025-12-18 16:00:15.591658', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (112, 25, 128, '2025-12-18 16:01:25.101922', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (117, 13, 82, '2025-12-31 14:54:03.572744', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (118, 13, 31, '2025-12-31 14:54:03.596248', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (44, 139, 140, '2025-12-17 08:25:16.015548', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (45, 139, 141, '2025-12-17 08:25:31.117264', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (50, 63, 46, '2025-12-17 10:23:49.426594', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (51, 11, 4, '2025-12-17 10:28:31.410621', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (58, 24, 14, '2025-12-17 15:10:28.837987', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (59, 18, 21, '2025-12-17 15:14:43.436497', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (60, 18, 82, '2025-12-17 15:17:27.618368', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (65, 100, 37, '2025-12-18 08:35:04.122403', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (69, 23, 63, '2025-12-18 08:39:20.522592', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (70, 100, 63, '2025-12-18 08:41:02.734992', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (71, 49, 55, '2025-12-18 08:42:19.229062', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (73, 100, 49, '2025-12-18 08:44:11.414446', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (75, 85, 17, '2025-12-18 08:46:41.421655', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (76, 49, 50, '2025-12-18 08:47:33.542173', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (77, 18, 1, '2025-12-18 08:55:11.389724', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (78, 1, 6, '2025-12-18 08:59:21.309456', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (79, 52, 131, '2025-12-18 09:03:11.445612', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (80, 52, 36, '2025-12-18 09:03:31.959673', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (81, 1, 52, '2025-12-18 09:04:23.405868', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (82, 18, 52, '2025-12-18 09:06:24.351491', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (83, 133, 90, '2025-12-18 09:17:04.823468', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (84, 133, 132, '2025-12-18 09:17:04.855033', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (85, 133, 27, '2025-12-18 09:17:04.946953', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (86, 133, 5, '2025-12-18 09:17:04.960284', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (87, 133, 41, '2025-12-18 09:17:04.972706', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (88, 133, 15, '2025-12-18 09:17:04.980099', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (91, 49, 133, '2025-12-18 13:27:01.820702', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (92, 20, 138, '2025-12-18 13:30:52.906541', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (93, 75, 135, '2025-12-18 13:39:01.592', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (126, 1, 18, '2026-01-05 09:40:36.726562', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (231, 336, 341, '2026-02-27 08:55:30.69429', NULL, NULL, 10, 'backed_up_by', 'backward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (232, 336, 340, '2026-02-27 09:21:29.565758', NULL, NULL, 10, 'consumed_by', 'backward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (237, 29, 57, '2026-02-27 09:36:53.619528', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (238, 29, 99, '2026-02-27 09:36:54.224257', NULL, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (239, 29, NULL, '2026-02-27 09:36:55.543233', 10, NULL, 1, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (242, 337, 338, '2026-02-27 09:41:54.726263', NULL, NULL, 10, 'part_of', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (253, 211, 212, '2026-03-05 18:46:56.01877', NULL, NULL, 10, 'backed_up_by', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (259, 211, 214, '2026-03-05 19:11:18.481293', NULL, NULL, 10, 'consumed_by', 'backward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (264, 214, 213, '2026-03-05 19:58:59.099359', NULL, NULL, 10, 'connects_to', 'bidirectional', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (275, 393, 397, '2026-03-13 19:59:30.59081', NULL, NULL, 27, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (276, 394, 395, '2026-03-13 20:00:17.77842', NULL, NULL, 27, 'depends_on', 'forward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (278, 392, 393, '2026-03-13 21:29:41.926588', NULL, NULL, 27, 'consumed_by', 'backward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (281, 342, 335, '2026-03-14 04:28:58.026974', NULL, NULL, 5, 'consumed_by', 'backward', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (406, NULL, 482, '2026-05-03 14:15:50.886385', NULL, NULL, 30, 'consumed_by', 'backward', NULL, NULL, NULL, 85) ON CONFLICT DO NOTHING;
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction, target_service_id, target_service_item_id, source_service_id, source_service_item_id) VALUES (364, NULL, 473, '2026-05-03 00:11:54.883432', NULL, NULL, 12, 'depends_on', 'forward', NULL, NULL, NULL, 95) ON CONFLICT DO NOTHING;


--
-- TOC entry 5383 (class 0 OID 30546)
-- Dependencies: 227
-- Data for Name: cross_service_connections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (3, 56, 53, 5, 'consumed_by', 'forward', '2026-03-13 22:33:03.827636', '2026-03-13 22:33:13.67433', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (14, 33, 44, 27, 'consumed_by', 'forward', '2026-03-17 14:42:27.394263', '2026-03-17 14:42:27.394263', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (19, 80, 77, 27, 'connects_to', 'forward', '2026-04-01 09:33:26.562847', '2026-04-01 09:33:26.562847', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (20, 82, 76, 27, 'consumed_by', 'forward', '2026-04-01 09:45:13.675288', '2026-04-01 09:45:13.675288', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (21, 81, 78, 27, 'consumed_by', 'forward', '2026-04-01 09:45:34.557796', '2026-04-01 09:45:34.557796', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (22, 83, 79, 27, 'consumed_by', 'forward', '2026-04-01 09:46:03.284143', '2026-04-01 09:46:03.284143', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (26, 92, 84, 30, 'consumed_by', 'forward', '2026-04-27 08:19:38.41122', '2026-04-27 08:19:38.41122', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (29, 93, 85, 30, 'connects_to', 'forward', '2026-04-29 09:13:35.220187', '2026-04-29 09:13:35.220187', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (30, 85, 84, 30, 'connects_to', 'forward', '2026-04-29 10:13:58.753335', '2026-04-29 10:13:58.753335', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (35, 89, 86, 28, 'connects_to', 'forward', '2026-05-03 00:03:40.831418', '2026-05-03 00:03:40.831418', true) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_connections (id, source_service_item_id, target_service_item_id, workspace_id, connection_type, direction, created_at, updated_at, propagation_enabled) VALUES (36, 91, 85, 30, 'consumed_by', 'forward', '2026-05-03 11:45:33.666677', '2026-05-03 11:45:33.666677', true) ON CONFLICT DO NOTHING;


--
-- TOC entry 5385 (class 0 OID 30560)
-- Dependencies: 229
-- Data for Name: cross_service_edge_handles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (4, 'cross-service-55-56', 38, 39, 'source-top', 'target-left', 5, '2026-03-13 22:34:03.881976', '2026-03-13 22:34:03.881976', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (8, 'cross-service-67-61', 40, 41, 'source-bottom', 'target-left', 28, '2026-03-25 08:40:05.7734', '2026-03-25 11:10:21.163213', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (5, 'cross-service-58-61', 40, 41, 'source-bottom', 'target-right', 28, '2026-03-17 10:21:35.13117', '2026-03-25 11:10:23.86978', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (1, 'cross-service-33-44', 31, 32, 'source-bottom', 'target-top', 27, '2026-03-13 19:43:21.103877', '2026-04-01 10:04:27.325089', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (15, 'cross-service-83-79', 31, 43, 'source-bottom', 'target-top', 27, '2026-04-01 09:46:46.389327', '2026-04-01 10:58:23.160305', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (13, 'cross-service-82-76', 31, 43, 'source-bottom', 'target-top', 27, '2026-04-01 09:46:38.850343', '2026-04-01 10:58:39.220129', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (14, 'cross-service-81-78', 31, 43, 'source-bottom', 'target-top', 27, '2026-04-01 09:46:41.724105', '2026-04-01 11:00:28.55291', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (50, 'cross-service-83-79', 31, 43, 'source-top', 'target-bottom', 27, '2026-04-01 13:31:04.584726', '2026-04-01 13:31:10.221636', 43) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (52, 'cross-service-82-76', 31, 43, 'source-top', 'target-bottom', 27, '2026-04-01 13:31:17.176334', '2026-04-01 13:31:19.761862', 43) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (54, 'cross-service-81-78', 31, 43, 'source-top', 'target-bottom', 27, '2026-04-01 13:31:25.532308', '2026-04-01 13:31:28.661689', 43) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (56, 'cross-service-83-79', 31, 43, 'source-top', 'target-bottom', 27, '2026-04-01 13:32:18.731109', '2026-04-01 13:32:21.175869', 31) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (58, 'cross-service-82-76', 31, 43, 'source-top', 'target-bottom', 27, '2026-04-01 13:32:23.763925', '2026-04-01 13:32:26.854531', 31) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (60, 'cross-service-81-78', 31, 43, 'source-top', 'target-bottom', 27, '2026-04-01 13:32:31.761011', '2026-04-01 13:32:40.695016', 31) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (62, 'cross-service-87-89', 58, 56, 'source-bottom', 'target-left', 28, '2026-04-23 20:40:36.873452', '2026-04-23 20:40:36.873452', 58) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (63, 'cross-service-87-89', 58, 56, 'source-top', 'target-bottom', 28, '2026-04-23 20:40:57.083786', '2026-04-23 20:41:00.395291', 56) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (65, 'cross-service-90-87', 56, 58, 'source-left', 'target-right', 28, '2026-04-25 11:55:14.207907', '2026-04-25 11:55:16.44928', 58) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (69, 'cross-service-92-84', 50, 49, 'source-left', 'target-right', 30, '2026-04-27 13:34:55.128531', '2026-04-27 13:34:59.280285', 49) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (72, 'cross-service-92-84', 50, 49, 'source-bottom', 'target-top', 30, '2026-04-29 10:21:48.245782', '2026-04-29 10:21:51.359494', 50) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (75, 'cross-service-85-84', 47, 49, 'source-left', 'target-top', 30, '2026-04-30 09:12:18.515739', '2026-04-30 09:12:23.156715', 49) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (77, 'cross-service-85-84', 47, 49, 'source-right', 'target-left', 30, '2026-05-05 08:36:52.204167', '2026-05-05 08:36:55.307687', 47) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (67, 'cross-service-91-85', 50, 47, 'source-right', 'target-top', 30, '2026-04-27 08:24:07.164769', '2026-05-05 10:09:46.767077', 47) ON CONFLICT DO NOTHING;
INSERT INTO public.cross_service_edge_handles (id, edge_id, source_service_id, target_service_id, source_handle, target_handle, workspace_id, created_at, updated_at, viewing_service_id) VALUES (71, 'cross-service-91-85', 50, 47, 'source-right', 'target-top', 30, '2026-04-29 10:21:45.700765', '2026-05-05 10:33:06.910525', 50) ON CONFLICT DO NOTHING;


--
-- TOC entry 5387 (class 0 OID 30575)
-- Dependencies: 231
-- Data for Name: edge_handles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (109, 'e170-169', 'source-right', 'target-left', '2026-01-20 08:08:32.454551', '2026-01-20 08:08:39.080239', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (78, 'e29-99', 'source-bottom', 'target-top', '2026-01-02 14:13:15.276464', '2026-01-02 14:13:23.718112', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (79, 'e29-57', 'source-top', 'target-left', '2026-01-02 14:12:48.837476', '2026-01-02 14:13:27.16148', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (80, 'e63-46', 'source-right', 'target-left', '2026-01-02 14:13:51.044416', '2026-01-02 14:13:56.641687', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (81, 'e23-63', 'source-bottom', 'target-bottom', '2026-01-02 14:14:19.652016', '2026-01-02 14:14:19.652016', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (82, 'e100-37', 'source-bottom', 'target-bottom', '2026-01-02 14:15:26.879452', '2026-01-02 14:15:26.879452', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (83, 'e100-63', 'source-top', 'target-bottom', '2026-01-02 14:14:03.113504', '2026-01-02 14:15:40.724184', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (84, 'e100-49', 'source-bottom', 'target-bottom', '2026-01-02 14:15:30.773093', '2026-01-02 14:15:43.599896', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (85, 'e10-136', 'source-right', 'target-bottom', '2026-01-02 14:15:55.055167', '2026-01-02 14:15:55.055167', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (86, 'e11-4', 'source-right', 'target-left', '2026-01-02 14:16:04.087073', '2026-01-02 14:16:06.333116', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (87, 'e48-66', 'source-left', 'target-right', '2026-01-02 14:16:11.9354', '2026-01-02 14:16:14.381967', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (88, 'e48-9', 'source-right', 'target-bottom', '2026-01-02 14:16:20.281089', '2026-01-02 14:16:20.281089', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (89, 'e85-17', 'source-top', 'target-top', '2026-01-02 14:16:27.985222', '2026-01-02 14:16:27.985222', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (90, 'e20-138', 'source-bottom', 'target-bottom', '2026-01-02 14:16:35.568098', '2026-01-02 14:16:35.568098', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (91, 'e49-55', 'source-bottom', 'target-bottom', '2026-01-02 14:16:42.328915', '2026-01-02 14:16:42.328915', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (92, 'e49-50', 'source-bottom', 'target-bottom', '2026-01-02 14:16:44.932811', '2026-01-02 14:16:44.932811', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (93, 'e13-82', 'source-bottom', 'target-bottom', '2026-01-02 14:18:07.509484', '2026-01-02 14:18:07.509484', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (94, 'e13-31', 'source-bottom', 'target-bottom', '2026-01-02 14:18:10.659532', '2026-01-02 14:18:10.659532', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (95, 'e1-6', 'source-bottom', 'target-left', '2026-01-02 14:18:43.727463', '2026-01-02 14:18:43.727463', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (97, 'e18-1', 'source-bottom', 'target-bottom', '2026-01-02 14:18:15.138929', '2026-01-02 14:19:21.174823', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (98, 'e18-82', 'source-bottom', 'target-bottom', '2026-01-02 14:18:05.079066', '2026-01-02 14:19:23.644101', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (99, 'e75-92', 'source-right', 'target-bottom', '2026-01-02 14:19:29.792274', '2026-01-02 14:19:29.792274', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (100, 'e52-131', 'source-top', 'target-top', '2026-01-02 14:20:12.132843', '2026-01-02 14:20:12.132843', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (101, 'e1-52', 'source-bottom', 'target-bottom', '2026-01-02 14:18:27.398266', '2026-01-02 14:20:17.511688', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (102, 'e52-36', 'source-bottom', 'target-left', '2026-01-02 14:18:38.199577', '2026-01-02 14:20:19.550056', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (103, 'e18-52', 'source-bottom', 'target-bottom', '2026-01-02 14:18:24.497389', '2026-01-02 14:20:25.340217', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (104, 'e24-14', 'source-right', 'target-left', '2026-01-02 14:22:09.645056', '2026-01-02 14:22:12.580145', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (105, 'group-e7-9', 'source-bottom', 'target-top', '2026-01-05 16:26:03.088024', '2026-01-05 16:26:06.18634', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (106, 'group-e7-8', 'source-bottom', 'target-top', '2026-01-05 16:25:34.464373', '2026-01-05 16:26:09.346589', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (107, 'e29-group10', 'source-left', 'target-top', '2026-01-05 16:26:23.267144', '2026-01-05 16:26:23.267144', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (108, 'e1-18', 'source-bottom', 'target-bottom', '2026-01-19 07:32:51.923639', '2026-01-19 07:32:51.923639', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (177, 'e213-211', 'source-right', 'target-left', '2026-02-26 14:18:52.772725', '2026-02-26 14:18:56.996192', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (184, 'e213-212', 'source-bottom', 'target-top', '2026-02-27 08:29:26.517204', '2026-02-27 08:29:35.508256', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (187, 'e336-341', 'source-right', 'target-top', '2026-02-27 09:18:10.834161', '2026-02-27 09:18:50.975846', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (194, 'e336-340', 'source-top', 'target-left', '2026-02-27 09:21:34.080121', '2026-02-27 09:21:42.470414', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (196, 'e337-338', 'source-bottom', 'target-left', '2026-03-05 08:57:06.519', '2026-03-05 08:57:06.519', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (179, 'e211-214', 'source-bottom', 'target-bottom', '2026-02-26 14:23:38.336683', '2026-03-05 17:51:36.541975', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (202, 'e213-214', 'source-left', 'target-top', '2026-03-05 17:55:37.120485', '2026-03-05 17:55:37.120485', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (203, 'e212-211', 'source-left', 'target-right', '2026-03-05 17:58:12.017732', '2026-03-05 17:58:14.115562', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (205, 'e212-214', 'source-left', 'target-right', '2026-03-05 18:00:46.309958', '2026-03-05 18:00:57.600789', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (207, 'e214-211', 'source-bottom', 'target-left', '2026-03-05 18:43:27.957205', '2026-03-05 18:43:27.957205', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (180, 'e211-212', 'source-right', 'target-right', '2026-02-26 14:32:39.299392', '2026-03-05 18:47:51.528948', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (210, 'e365-214', 'source-bottom', 'target-left', '2026-03-05 20:16:37.012182', '2026-03-05 20:16:37.012182', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (199, 'e214-213', 'source-top', 'target-bottom', '2026-03-05 17:51:30.305902', '2026-03-05 21:08:55.41004', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (212, 'group72-e213', 'source-right', 'target-top', '2026-03-05 21:08:57.027289', '2026-03-05 21:08:57.027289', 10) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (96, 'e18-21', 'source-top', 'target-bottom', '2026-01-02 14:18:50.664474', '2026-03-11 10:50:08.148217', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (214, 'e392-393', 'source-left', 'target-right', '2026-03-12 14:56:36.076938', '2026-03-12 14:56:42.431518', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (216, 'e395-397', 'source-right', 'target-bottom', '2026-03-13 20:00:24.65029', '2026-03-13 20:00:28.242221', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (218, 'e342-335', 'source-top', 'target-right', '2026-03-14 04:29:01.235575', '2026-03-14 04:29:04.941949', 5) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (220, 'e448-group80', 'source-top', 'target-top', '2026-03-30 14:16:32.746018', '2026-03-30 14:16:40.828249', 29) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (222, 'e451-449', 'source-top', 'target-bottom', '2026-03-31 09:24:57.664896', '2026-03-31 09:25:01.122315', 29) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (224, 'e394-395', 'source-bottom', 'target-top', '2026-04-01 09:36:42.040063', '2026-04-01 10:02:51.976746', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (228, 'e393-397', 'source-bottom', 'target-right', '2026-04-16 14:57:40.513857', '2026-04-16 14:57:40.513857', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (237, 'layanan-edge-14', 'bottom', 'target-top', '2026-04-21 10:24:56.966293', '2026-04-21 10:24:56.966293', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (238, 'layanan-edge-15', 'bottom', 'target-top', '2026-04-21 10:43:58.794152', '2026-04-21 10:43:58.794152', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (239, 'layanan-edge-16', 'source-bottom', 'right-target', '2026-04-21 10:44:13.972653', '2026-04-21 10:44:26.908418', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (242, 'layanan-edge-18', 'bottom', 'target-top', '2026-04-21 13:09:40.629743', '2026-04-21 13:09:40.629743', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (243, 'layanan-edge-19', 'bottom', 'target-top', '2026-04-21 13:42:35.176144', '2026-04-21 13:42:35.176144', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (244, 'layanan-edge-20', 'bottom', 'target-top', '2026-04-21 13:57:31.700548', '2026-04-21 13:57:31.700548', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (245, 'layanan-edge-21', 'bottom', 'target-top', '2026-04-21 14:01:27.855906', '2026-04-21 14:01:27.855906', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (246, 'layanan-edge-22', 'bottom', 'target-top', '2026-04-21 14:01:36.520404', '2026-04-21 14:01:36.520404', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (248, 'service-connection-6', 'source-bottom', 'target-bottom', '2026-04-23 13:59:11.399981', '2026-04-23 13:59:11.399981', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (249, 'service-connection-7', 'source-top', 'target-left', '2026-04-23 14:01:21.580364', '2026-04-23 14:01:34.639549', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (251, 'layanan-edge-36', 'source-bottom', 'left-target', '2026-04-23 16:29:27.871193', '2026-04-23 16:29:36.895289', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (254, 'service-connection-9', 'source-right', 'target-left', '2026-04-23 19:18:47.400146', '2026-04-23 19:18:47.400146', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (255, 'e403-402', 'source-top', 'target-top', '2026-04-23 19:18:54.762937', '2026-04-23 19:18:54.762937', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (256, 'e401-402', 'source-right', 'target-top', '2026-04-23 20:28:53.05421', '2026-04-23 20:28:53.05421', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (257, 'layanan-edge-42', 'source-bottom', 'top', '2026-04-23 20:33:16.086482', '2026-04-23 20:33:28.886076', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (259, 'e466-404', 'source-right', 'target-left', '2026-04-23 20:36:19.206363', '2026-04-23 20:36:22.957416', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (261, 'layanan-edge-43', 'source-bottom', 'left-target', '2026-04-23 20:43:56.635289', '2026-04-23 20:43:56.635289', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (262, 'layanan-edge-57', 'bottom', 'target-right', '2026-04-23 21:41:16.623628', '2026-04-23 21:41:16.623628', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (263, 'layanan-edge-64', 'source-bottom', 'left-target', '2026-04-24 08:41:57.533235', '2026-04-24 08:41:57.533235', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (247, 'e403-401', 'source-top', 'target-left', '2026-04-22 16:58:56.924338', '2026-04-24 10:18:50.642173', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (265, 'layanan-edge-88', 'source-left', 'left-target', '2026-04-24 10:45:46.403986', '2026-04-24 10:45:48.424676', 27) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (267, 'layanan-edge-96', 'bottom', 'target-bottom', '2026-04-24 13:39:32.496895', '2026-04-24 13:39:36.219752', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (269, 'service-connection-19', 'source-right', 'target-left', '2026-04-25 01:09:43.907641', '2026-04-25 09:58:03.462447', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (271, 'service-connection-21', 'source-right-bottom', 'target-left', '2026-04-25 11:08:22.790451', '2026-04-25 11:40:01.071503', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (277, 'service-connection-26', 'source-right', 'target-left-top', '2026-04-27 08:08:10.957939', '2026-04-27 08:08:10.957939', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (278, 'layanan-edge-111', 'source-bottom', 'right-target', '2026-04-27 08:31:05.617459', '2026-04-27 09:15:19.822389', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (281, 'layanan-edge-113', 'bottom', 'target-top', '2026-04-27 09:31:07.406731', '2026-04-27 09:31:12.272888', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (283, 'layanan-edge-115', 'bottom', 'target-left-top', '2026-04-27 09:39:51.256735', '2026-04-27 09:39:51.256735', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (284, 'layanan-edge-119', 'bottom', 'target-left', '2026-04-27 10:51:02.591667', '2026-04-27 10:51:02.591667', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (285, 'layanan-edge-120', 'source-left', 'right-target', '2026-04-27 13:17:10.782707', '2026-04-27 13:17:18.912316', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (288, 'layanan-edge-121', 'source-bottom', 'right-target', '2026-04-27 16:11:02.662942', '2026-04-27 16:11:22.721086', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (287, 'service-connection-32', 'source-bottom', 'target-left', '2026-04-27 14:53:02.648902', '2026-04-29 09:27:02.583563', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (353, 'service-connection-38', 'source-bottom-left', 'target-bottom-right', '2026-04-30 08:55:59.906126', '2026-04-30 09:25:22.683265', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (290, 'layanan-edge-125', 'source-left', 'right-target', '2026-04-28 08:43:36.740677', '2026-04-28 09:41:08.923806', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (294, 'layanan-edge-127', 'source-bottom', 'right-target', '2026-04-28 09:45:30.723706', '2026-04-28 09:45:36.484167', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (296, 'layanan-edge-128', 'bottom', 'target-left-top', '2026-04-28 09:46:19.407271', '2026-04-28 09:46:21.857825', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (299, 'layanan-edge-135', 'source-bottom-left', 'top', '2026-04-28 10:04:41.584003', '2026-04-28 10:04:41.584003', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (298, 'service-connection-33', 'source-bottom', 'target-top', '2026-04-28 10:04:37.906417', '2026-04-28 10:04:44.030974', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (301, 'layanan-edge-138', 'bottom', 'target-left', '2026-04-28 10:12:29.089392', '2026-04-28 10:12:40.207585', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (303, 'layanan-edge-139', 'source-bottom', 'left-target', '2026-04-28 10:24:31.880597', '2026-04-28 10:24:31.880597', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (304, 'layanan-edge-140', 'source-bottom', 'right-target', '2026-04-28 10:25:28.48279', '2026-04-28 10:25:28.48279', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (305, 'layanan-edge-141', 'bottom', 'target-top', '2026-04-28 10:26:02.961414', '2026-04-28 10:26:06.931813', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (307, 'layanan-edge-143', 'source-bottom', 'right-target', '2026-04-28 10:35:23.940872', '2026-04-28 10:35:23.940872', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (348, 'service-connection-41', 'source-left', 'target-bottom-left', '2026-04-30 08:55:07.881018', '2026-04-30 09:25:28.090286', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (308, 'layanan-edge-148', 'source-bottom-left', 'right-target', '2026-04-28 13:46:58.6555', '2026-04-28 13:47:33.48355', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (317, 'layanan-edge-149', 'source-left', 'right-target', '2026-04-28 14:01:32.09104', '2026-04-28 14:01:54.171512', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (309, 'service-connection-35', 'source-bottom', 'target-left', '2026-04-28 13:47:12.495287', '2026-04-29 08:33:30.482385', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (312, 'service-connection-34', 'source-bottom-left', 'target-bottom-right', '2026-04-28 13:47:25.884542', '2026-04-29 08:33:56.264419', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (328, 'service-connection-37', 'source-bottom-right', 'target-left-bottom', '2026-04-29 09:12:27.208124', '2026-04-29 09:12:30.777741', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (327, 'service-connection-36', 'source-bottom', 'target-left-bottom', '2026-04-29 09:11:39.615346', '2026-04-29 09:27:00.362097', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (321, 'layanan-edge-150', 'source-left', 'right-target', '2026-04-28 14:16:18.003051', '2026-04-29 09:33:26.926217', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (330, 'cross-service-connection-27', 'source-left', 'target-right', '2026-04-29 09:23:39.075218', '2026-04-29 10:14:25.287947', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (334, 'cross-service-connection-26', 'source-bottom', 'target-left-top', '2026-04-29 09:26:53.735225', '2026-04-29 10:16:04.993162', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (347, 'service-connection-39', 'source-bottom-right', 'target-left-top', '2026-04-30 08:51:45.020775', '2026-04-30 09:25:06.178135', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (365, 'layanan-edge-151', 'bottom', 'target-left', '2026-05-01 14:48:34.81109', '2026-05-01 14:48:37.691627', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (475, 'cross-service-connection-35', 'source-left-bottom', 'target-top-right', '2026-05-03 00:04:01.119665', '2026-05-03 00:04:17.666602', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (367, 'layanan-edge-152', 'source-bottom-left', 'right-target', '2026-05-01 14:49:59.413187', '2026-05-01 14:50:14.552291', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (478, 'eservice-item-94-471', 'source-left', 'target-right', '2026-05-03 00:08:49.122975', '2026-05-03 00:08:53.264597', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (381, 'cross-service-connection-32', 'source-left', 'target-right-top', '2026-05-01 15:47:45.741296', '2026-05-02 23:23:28.430398', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (416, 'layanan-edge-164', 'source-bottom-left', 'top', '2026-05-01 18:00:27.594929', '2026-05-01 18:07:12.38468', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (424, 'layanan-edge-167', 'source-bottom', 'left-target', '2026-05-01 18:13:15.854115', '2026-05-01 18:13:24.891023', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (372, 'layana-service-edge-null', 'bottom', 'target-left', '2026-05-01 15:24:52.069123', '2026-05-01 15:48:11.029088', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (486, 'eservice-item-98-478', 'source-left', 'target-bottom', '2026-05-03 00:45:50.905591', '2026-05-03 00:45:53.478693', 33) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (480, 'e478-service-item-98', 'source-bottom', 'target-left-top', '2026-05-03 00:44:14.65765', '2026-05-03 10:41:42.408172', 33) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (426, 'e469-service-47', 'source-bottom', 'target-left-top', '2026-05-01 23:30:21.972434', '2026-05-02 11:36:36.216229', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (446, 'eservice-47-service-item-85', 'source-right-bottom', 'target-right', '2026-05-02 21:26:35.112272', '2026-05-02 23:24:13.589998', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (383, 'layana-service-edge-1', 'bottom', 'target-bottom-left', '2026-05-01 16:29:30.251267', '2026-05-01 16:47:22.393002', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (343, 'cross-service-connection-30', 'source-bottom-right', 'target-left-bottom', '2026-04-29 10:14:22.072773', '2026-05-02 23:25:01.52449', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (489, 'eservice-67-478', 'source-left', 'target-right', '2026-05-03 11:26:23.78728', '2026-05-03 11:26:25.254332', 33) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (437, 'eservice-47-469', 'source-left', 'target-bottom', '2026-05-02 13:56:27.413182', '2026-05-02 23:27:51.03547', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (396, 'layana-service-edge-2', 'source-left-bottom', 'left-target', '2026-05-01 16:53:39.314994', '2026-05-01 16:56:40.923762', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (491, 'e478-service-67', 'source-bottom', 'target-left-top', '2026-05-03 11:32:07.140769', '2026-05-03 11:32:07.140769', 33) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (402, 'layanan-edge-153', 'bottom', 'target-left', '2026-05-01 16:58:34.9039', '2026-05-01 17:09:13.111224', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (435, 'e469-service-item-85', 'source-bottom', 'target-left', '2026-05-02 12:14:59.509277', '2026-05-02 14:08:30.13627', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (492, 'e481-service-item-85', 'source-bottom', 'target-left-bottom', '2026-05-03 12:43:37.997976', '2026-05-03 12:43:37.997976', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (406, 'layanan-edge-154', 'left', 'target-left', '2026-05-01 17:18:31.653654', '2026-05-01 17:30:38.603238', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (411, 'layanan-edge-155', 'bottom', 'target-top', '2026-05-01 17:41:23.02336', '2026-05-01 17:41:23.02336', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (412, 'layanan-edge-156', 'bottom', 'target-top', '2026-05-01 17:41:46.154094', '2026-05-01 17:41:46.154094', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (413, 'layanan-edge-158', 'source-bottom', 'top', '2026-05-01 17:42:48.831499', '2026-05-01 17:42:48.831499', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (414, 'layanan-edge-159', 'bottom', 'target-top', '2026-05-01 17:42:58.450872', '2026-05-01 17:42:58.450872', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (469, 'eservice-item-85-469', 'source-bottom-left', 'target-right', '2026-05-02 23:37:07.848376', '2026-05-03 13:48:37.27728', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (473, 'cross-service-connection-34', 'source-bottom-right', 'target-bottom-left', '2026-05-02 23:59:28.846902', '2026-05-02 23:59:32.803109', 28) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (331, 'cross-service-connection-29', 'source-left', 'target-bottom', '2026-04-29 09:23:51.141449', '2026-05-03 14:16:06.149555', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (494, 'eservice-item-85-482', 'source-bottom-left', 'target-bottom', '2026-05-03 14:15:56.549744', '2026-05-03 14:16:09.411294', 30) ON CONFLICT DO NOTHING;
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (499, 'cross-service-connection-36', 'source-left', 'target-right', '2026-05-04 14:04:01.636448', '2026-05-04 14:04:52.940169', 30) ON CONFLICT DO NOTHING;


--
-- TOC entry 5389 (class 0 OID 30586)
-- Dependencies: 233
-- Data for Name: external_item_positions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (18, 5, 38, 56, '{"x": -205.59398995234642, "y": -300.1491735587452}', '2026-03-13 22:33:21.557592', '2026-03-13 22:33:21.557592', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (19, 5, 39, 53, '{"x": 95.3232224594575, "y": -156.66115681697488}', '2026-03-13 22:34:30.152282', '2026-03-13 22:34:28.350645', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (21, 5, 39, 55, '{"x": -120.48684104417293, "y": 78.17473125505632}', '2026-03-13 22:34:31.615428', '2026-03-13 22:34:31.615428', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (8, 27, 32, 33, '{"x": -436.48967785348617, "y": 142.27532709131037}', '2026-03-14 04:45:35.152232', '2026-03-13 19:43:41.649738', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (1, 27, 31, 44, '{"x": -432.84890287156895, "y": 414.793190305936}', '2026-04-01 10:04:30.718955', '2026-03-13 09:51:48.260847', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (57, 27, 31, 76, '{"x": 39.287839448355726, "y": 414.3405656587227}', '2026-04-01 10:05:57.234518', '2026-04-01 10:04:46.097112', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (56, 27, 31, 78, '{"x": 277.119722300597, "y": 413.0880356835082}', '2026-04-01 10:06:14.006821', '2026-04-01 10:04:40.053248', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (55, 27, 31, 79, '{"x": -208.43034654211021, "y": 414.8967643851289}', '2026-04-01 10:58:24.232364', '2026-04-01 10:04:36.084895', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (46, 27, 43, 80, '{"x": 39.540207094109746, "y": 12.075134380512793}', '2026-04-16 15:05:29.214903', '2026-04-01 09:33:37.869354', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (64, 27, 43, 82, '{"x": 26.225353958390542, "y": 500.8566040705007}', '2026-04-16 15:05:29.182384', '2026-04-01 10:07:07.491761', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (63, 27, 43, 81, '{"x": 273.6481863893671, "y": 493.88763824098635}', '2026-04-16 15:05:29.247966', '2026-04-01 10:07:04.592207', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (50, 27, 43, 83, '{"x": -245.1604145234228, "y": 498.71025382574624}', '2026-04-16 15:05:29.362303', '2026-04-01 09:50:41.084921', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (102, 28, 58, 89, '{"x": 149.000001538976, "y": 455.00000469955745}', '2026-04-25 10:32:09.35024', '2026-04-23 20:40:31.587089', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (106, 28, 56, 87, '{"x": 434, "y": 422}', '2026-04-25 10:41:03.484582', '2026-04-23 20:40:54.08229', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (121, 30, 47, 84, '{"x": 574.2361814971018, "y": 284.9595559474877}', '2026-05-05 09:39:16.384454', '2026-04-29 10:17:20.644687', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (114, 30, 47, 91, '{"x": 303.4223856835953, "y": -95.22173480285457}', '2026-05-05 09:39:16.382068', '2026-04-27 08:23:56.157328', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (116, 30, 47, 93, '{"x": 31.79006158219704, "y": 47.81590103491874}', '2026-05-05 09:39:16.391605', '2026-04-27 08:33:45.773344', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (115, 30, 48, 85, '{"x": 357.321411740975, "y": -89.31725304596631}', '2026-05-05 08:38:42.932067', '2026-04-27 08:33:32.175685', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (179, 30, 49, 84, '{"x": 645.2299035432434, "y": 148.95955594748767}', '2026-05-05 10:09:35.166337', '2026-05-05 09:39:13.661869', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (130, 30, 49, 85, '{"x": 372.61697224571117, "y": -56.96804609135302}', '2026-05-05 09:00:45.86211', '2026-04-30 09:12:28.970168', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (118, 30, 49, 92, '{"x": 365.3099512083161, "y": 192.88129485057044}', '2026-05-05 09:00:45.865235', '2026-04-27 13:35:01.096126', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (197, 30, 50, 91, '{"x": 72.4248851684207, "y": 22.872492988611157}', '2026-05-05 10:09:50.489306', '2026-05-05 10:09:39.279614', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (196, 30, 48, 93, '{"x": 74.61544089119013, "y": 285.3020953847893}', '2026-05-05 10:09:54.692412', '2026-05-05 10:09:37.415585', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (188, 30, 47, 85, '{"x": 618.840649247863, "y": 222.61798832510516}', '2026-05-05 10:14:07.485965', '2026-05-05 09:55:16.437195', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (122, 30, 50, 85, '{"x": 618.840649247863, "y": 222.61798832510516}', '2026-05-05 10:14:08.886783', '2026-04-29 10:21:42.550914', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.external_item_positions (id, workspace_id, service_id, external_service_item_id, "position", updated_at, created_at, is_auto_layouted, layout_hash) VALUES (112, 30, 50, 84, '{"x": 351.7232654692673, "y": 280.69824167735834}', '2026-05-05 10:14:08.8891', '2026-04-27 08:18:25.949444', false, NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 5393 (class 0 OID 30637)
-- Dependencies: 238
-- Data for Name: group_connections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.group_connections (id, source_id, target_id, created_at, workspace_id, connection_type, direction) VALUES (5, 7, 8, '2025-12-17 15:00:31.367842', 1, 'depends_on', 'forward') ON CONFLICT DO NOTHING;
INSERT INTO public.group_connections (id, source_id, target_id, created_at, workspace_id, connection_type, direction) VALUES (10, 7, 18, '2026-01-06 06:38:43.171011', 1, 'depends_on', 'forward') ON CONFLICT DO NOTHING;
INSERT INTO public.group_connections (id, source_id, target_id, created_at, workspace_id, connection_type, direction) VALUES (11, 18, 8, '2026-01-06 06:39:00.226361', 1, 'depends_on', 'forward') ON CONFLICT DO NOTHING;


--
-- TOC entry 5395 (class 0 OID 30646)
-- Dependencies: 240
-- Data for Name: service_connections; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5397 (class 0 OID 30660)
-- Dependencies: 242
-- Data for Name: service_edge_handles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (7, 'service-group-e1-3', 'source-top', 'target-left', 11, 5, '2026-02-18 11:04:45.680949', '2026-02-18 11:04:58.619476') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (1, 'e13-12', 'source-left', 'target-top', 11, 5, '2026-02-10 09:47:40.827586', '2026-02-18 11:05:09.373918') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (10, 'e25-19', 'source-top', 'target-left', 19, 5, '2026-02-18 16:14:49.02613', '2026-02-19 08:25:46.303272') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (16, 'e23-20', 'source-right', 'target-bottom', 19, 5, '2026-02-19 08:48:27.706042', '2026-02-19 08:48:27.706042') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (15, 'e23-21', 'source-right', 'target-bottom', 19, 5, '2026-02-19 08:48:12.708552', '2026-02-25 11:22:38.350079') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (19, 'e18-15', 'source-top', 'target-bottom', 12, 5, '2026-03-14 04:26:46.917344', '2026-03-14 04:26:46.917344') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (20, 'e60-57', 'source-bottom', 'target-top', 40, 28, '2026-03-17 09:20:29.83769', '2026-03-17 09:20:29.83769') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (21, 'e65-58', 'source-bottom', 'target-top', 40, 28, '2026-03-25 11:09:11.912498', '2026-03-25 11:09:11.912498') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (22, 'e58-65', 'source-top', 'target-bottom', 40, 28, '2026-03-25 11:09:40.309903', '2026-03-25 11:09:40.309903') ON CONFLICT DO NOTHING;
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (23, 'e87-88', 'source-top', 'target-bottom', 58, 28, '2026-04-23 18:52:54.638583', '2026-04-23 20:40:34.160406') ON CONFLICT DO NOTHING;


--
-- TOC entry 5399 (class 0 OID 30672)
-- Dependencies: 244
-- Data for Name: service_group_connections; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5401 (class 0 OID 30682)
-- Dependencies: 246
-- Data for Name: service_groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.service_groups (id, service_id, name, description, color, "position", created_at, workspace_id) VALUES (2, 9, 'Group 1', '', '#e0e7ff', '{"x": 42.91413033517073, "y": 90.69223230920223}', '2026-02-18 09:12:47.94676', 1) ON CONFLICT DO NOTHING;
INSERT INTO public.service_groups (id, service_id, name, description, color, "position", created_at, workspace_id) VALUES (5, 19, 'G1', '', '#e0e7ff', '{"x": -26.068248250836405, "y": 163.3477296456947}', '2026-02-18 14:49:51.335641', 5) ON CONFLICT DO NOTHING;
INSERT INTO public.service_groups (id, service_id, name, description, color, "position", created_at, workspace_id) VALUES (6, 19, 'G2', '', '#e0e7ff', '{"x": 587.0645463289022, "y": -35.81795959213662}', '2026-02-18 14:49:56.122666', 5) ON CONFLICT DO NOTHING;
INSERT INTO public.service_groups (id, service_id, name, description, color, "position", created_at, workspace_id) VALUES (11, 42, 'G1', '', '#e0e7ff', '{"x": 511.9296248989117, "y": 108.8738666210549}', '2026-03-31 08:28:04.065004', 29) ON CONFLICT DO NOTHING;
INSERT INTO public.service_groups (id, service_id, name, description, color, "position", created_at, workspace_id) VALUES (12, 42, '44', '', '#e0e7ff', '{"x": 99.46340420296974, "y": 53.16325936411019}', '2026-03-31 09:15:58.667688', 29) ON CONFLICT DO NOTHING;


--
-- TOC entry 5391 (class 0 OID 30601)
-- Dependencies: 235
-- Data for Name: service_items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (10, 9, 'Web', 'server', '', '{"x": 262.4659515087648, "y": 287.518685576054}', 'active', '', 'internal', '', 1, '2026-02-06 16:05:28.205574', '2026-02-09 10:22:02.098067', NULL, 0, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (19, 19, '1', 'server', '', '{"x": 15, "y": 55}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:12.447289', '2026-02-19 08:48:38.934342', 5, 0, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (20, 19, '2', 'server', '', '{"x": 185, "y": 55}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:15.378402', '2026-02-19 08:48:38.935852', 5, 0, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (25, 19, '7', 'server', '', '{"x": -414.0706891814734, "y": 309.23300092575835}', 'active', '', 'internal', '', 5, '2026-02-18 16:13:31.742778', '2026-02-19 08:48:38.941247', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (23, 19, '5', 'server', '', '{"x": -264.5037375269838, "y": 575.5819274472655}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:20.271443', '2026-02-19 08:48:39.022471', NULL, 1, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (24, 19, '6', 'server', '', '{"x": 568.6693926644159, "y": 416.9095926687139}', 'active', '', 'internal', '', 5, '2026-02-18 16:13:27.005321', '2026-02-19 08:48:39.049175', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (26, 20, '1', 'server', '', '{"x": 168.098736344937, "y": 216.49478865596365}', 'active', '', 'internal', '', 5, '2026-02-24 11:31:59.926917', '2026-02-24 11:32:05.77769', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (22, 19, '4', 'server', '', '{"x": 15, "y": 165}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:19.073516', '2026-02-19 08:48:38.971905', 5, 2, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (21, 19, '3', 'server', '', '{"x": 355, "y": 55}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:17.725485', '2026-02-19 08:48:39.004233', 5, 3, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (15, 12, 'Test 1', 'server', '', '{"x": -8.78520243151354, "y": 332.53011818616653}', 'active', '', 'internal', '', 5, '2026-02-18 11:16:49.147725', '2026-02-26 13:24:00.369541', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (16, 12, 'Test 2', 'server', '', '{"x": 409, "y": 181}', 'active', '', 'internal', '', 5, '2026-02-18 11:17:04.600546', '2026-02-26 13:24:00.370945', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (17, 12, 'Test 3', 'server', '', '{"x": 215.27984619796428, "y": 373.26501111839394}', 'active', '', 'internal', '', 5, '2026-02-18 11:33:30.307396', '2026-02-26 13:24:00.372137', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (27, 24, '1', 'server', '', '{"x": 9.601042107211066, "y": 91.51961274031143}', 'active', '', 'internal', '', 10, '2026-03-04 14:25:59.931091', '2026-03-04 14:25:59.931091', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (48, 32, 'Gateway Dev', 'server', '', '{"x": 227.92327475873628, "y": 346.59194067158865}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:31:07.632859', '2026-03-13 19:48:54.825337', NULL, NULL, 'stock.tps.co.id', 8333) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (56, 39, 'OracleItem', 'server', '', '{"x": -205.59398995234642, "y": -300.1491735587452}', 'maintenance', '', 'internal', '', 5, '2026-03-13 22:32:37.17986', '2026-03-14 04:40:08.33651', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (43, 32, 'Auth', 'server', '', '{"x": 12.898098167866351, "y": 527.633423670411}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:27:18.694378', '2026-03-13 19:48:59.899628', NULL, NULL, 'auth.tps.co.id', 8484) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (46, 32, 'Elektra', 'server', '', '{"x": 427.34294743101884, "y": 527.0792072676347}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:29:06.613481', '2026-03-13 19:48:59.900574', NULL, NULL, 'edoc.tps.co.id', 7008) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (54, 38, 'MCR1', 'microservice', '', '{"x": 290.7858701260287, "y": -24.67676182181941}', 'active', '', 'internal', '', 5, '2026-03-13 21:39:23.446585', '2026-03-13 21:44:20.82717', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (44, 32, 'Kantin', 'server', '', '{"x": -432.84890287156895, "y": 414.793190305936}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:27:48.961374', '2026-04-02 08:36:30.969163', NULL, NULL, 'canteen.tps.co.id', 83) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (45, 32, 'API Gateway', 'server', '', '{"x": 427.41014155845585, "y": 343.9662420921805}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:28:27.967463', '2026-03-13 19:48:54.822295', NULL, NULL, 'api.tps.co.id', 8484) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (47, 32, 'Portal TPS', 'server', '', '{"x": 233.69809268852475, "y": 525.3024976035373}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:30:00.34283', '2026-03-13 19:48:54.823839', NULL, NULL, 'gss.tps.co.id', 82) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (53, 38, 'Test 1GG', 'api_service', '', '{"x": 95.3232224594575, "y": -156.66115681697488}', 'active', '', 'internal', '', 5, '2026-03-13 21:38:52.397783', '2026-03-13 22:34:33.669204', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (18, 12, 'Test 4', 'server', '', '{"x": 37.99263152232538, "y": 585.916326367569}', 'active', '', 'internal', '', 5, '2026-02-18 11:33:57.963987', '2026-03-14 04:26:42.833294', NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (55, 38, 'LLKS', 'mail_server', '', '{"x": -150.48684104417293, "y": 94.17473125505632}', 'active', '', 'internal', '', 5, '2026-03-13 21:39:37.097424', '2026-03-14 04:16:04.095288', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (52, 37, 'My TPS Vendor Admin', 'server', '', '{"x": 202.4268229789211, "y": 118.67580316694651}', 'active', '172.19.154.42', 'internal', '', 27, '2026-03-12 13:43:55.696981', '2026-04-21 15:59:55.584116', NULL, NULL, 'vss.tps.co.id', 32005) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (41, 33, 'QR Portal', 'server', '', '{"x": 353.649024377824, "y": 41.06528142872418}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:25:12.669772', '2026-04-16 14:19:00.547142', NULL, NULL, 'portal.tps.co.id', 84) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (81, 31, 'Opname Database', 'database', '', '{"x": 266.8641966727598, "y": 695.142806264625}', 'active', '', 'internal', '', 27, '2026-04-01 09:39:42.77514', '2026-04-16 14:19:42.600409', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (40, 33, 'Working Permit', 'server', '', '{"x": 162.75539214785888, "y": 41.49407857663502}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:24:38.329731', '2026-04-16 14:18:56.086743', NULL, NULL, 'gss.tps.co.id', 82) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (50, 36, 'Alesys', 'server', '', '{"x": 55.84568556280569, "y": 266.00251254732075}', 'active', '172.19.154.42', 'internal', '', 27, '2026-03-12 13:42:08.167155', '2026-04-21 16:00:06.072644', NULL, NULL, 'alesys.tps.co.id', 8111) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (34, 31, 'Gateway Database', 'database', '', '{"x": -441.1569842608682, "y": 17.482406277855034}', 'active', '172.19.155.50', 'internal', '', 27, '2026-03-11 13:38:55.261448', '2026-04-16 14:18:40.164194', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (76, 43, 'Permisson', 'server', '', '{"x": 36.63782541426531, "y": 289.7899060564733}', 'active', '', 'internal', '', 27, '2026-04-01 09:24:39.838085', '2026-04-16 15:05:46.277344', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (80, 44, 'Canteen Frontend', 'web_application', '', '{"x": 39.540207094109746, "y": 12.075134380512793}', 'active', '', 'internal', '', 27, '2026-04-01 09:32:30.045435', '2026-04-16 14:17:13.668575', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (77, 43, 'Canteen Backend', 'server', '', '{"x": 346.37545408968185, "y": 24.276332485238754}', 'active', '', 'internal', '', 27, '2026-04-01 09:24:47.997533', '2026-04-16 14:16:43.051862', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (51, 36, 'Elektra', 'server', '', '{"x": 238.58935815088654, "y": 265.7909251505937}', 'active', '172.19.154.42', 'internal', '', 27, '2026-03-12 13:42:43.910871', '2026-04-21 16:00:11.141498', NULL, NULL, 'elektra.tps.co.id', 8111) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (70, 42, 'asd2', 'server', '', '{"x": 15, "y": 55}', 'active', '', 'internal', '', 29, '2026-03-31 08:27:33.605454', '2026-03-31 09:14:07.669405', 11, 0, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (71, 42, '134', 'server', '', '{"x": 15, "y": 55}', 'active', '', 'internal', '', 29, '2026-03-31 09:06:37.746293', '2026-03-31 09:14:10.033797', 11, 0, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (69, 42, 'asd', 'server', '', '{"x": 15, "y": 55}', 'active', '', 'internal', '', 29, '2026-03-31 08:27:27.17769', '2026-03-31 16:20:23.744219', 11, 0, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (79, 43, 'Attendance', 'server', '', '{"x": -232.28047284892386, "y": 298.29614688515073}', 'active', '', 'internal', '', 27, '2026-04-01 09:27:37.333732', '2026-04-16 14:17:02.110553', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (33, 31, 'Kantin Database', 'database', '', '{"x": -434.4896778534862, "y": 148.27532709131037}', 'active', '172.19.155.50', 'internal', '', 27, '2026-03-11 13:38:34.094558', '2026-04-16 14:18:34.438929', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (35, 31, 'Gateway Database Dev', 'database', '', '{"x": -225.65630852545974, "y": 17.457317617626245}', 'active', '172.19.155.50', 'internal', '', 27, '2026-03-11 13:39:13.494432', '2026-04-16 14:18:45.597605', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (42, 33, 'Meeting Room Pengguna', 'server', '', '{"x": 543.0683846987198, "y": 41.18553690419236}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-12 08:25:56.614733', '2026-04-16 14:19:05.62751', NULL, NULL, 'room.tps.co.id', 8589) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (83, 31, 'Attendance Database', 'database', '', '{"x": -217.83824766290297, "y": 703.6265052796449}', 'active', '', 'internal', '', 27, '2026-04-01 09:40:24.913323', '2026-04-16 14:19:32.1467', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (82, 31, 'Permisson Database', 'database', '', '{"x": 29.64062481595556, "y": 695.5270429517044}', 'active', '', 'internal', '', 27, '2026-04-01 09:40:01.109195', '2026-04-16 14:19:37.673411', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (78, 43, 'Opname', 'server', '', '{"x": 283.9921864820293, "y": 288.2606598063812}', 'active', '', 'internal', '', 27, '2026-04-01 09:25:08.132599', '2026-04-16 15:05:29.310751', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (86, 57, 'aa1', 'server', '', '{"x": 289.12593589882414, "y": 240.32383466577954}', 'active', '', 'internal', '', 28, '2026-04-23 13:47:34.218651', '2026-04-27 08:07:17.504089', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (87, 58, 'asd', 'server', '', '{"x": 36.31952159760865, "y": 134.57811510695444}', 'active', '', 'internal', '', 28, '2026-04-23 18:52:45.312853', '2026-04-27 08:07:25.7247', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (89, 56, 'zz', 'server', '', '{"x": 153.81039531968335, "y": 45.90376035479259}', 'active', '', 'internal', '', 28, '2026-04-23 20:39:57.79923', '2026-05-02 23:58:02.269143', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (90, 56, 'asdasd', 'server', '', '{"x": 10.908086977934829, "y": 365.3655053735613}', 'active', '', 'internal', '', 28, '2026-04-25 10:41:00.092237', '2026-05-02 23:58:06.514084', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (88, 58, 'asdasd', 'server', '', '{"x": 365.09660170761254, "y": -29.572742188510233}', 'active', '', 'internal', '', 28, '2026-04-23 18:52:46.978407', '2026-05-02 23:58:40.307071', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (94, 63, '4126123', 'load_balancer', '', '{"x": 123.53026402514958, "y": 285.70448966515454}', 'inactive', '', 'internal', '', 28, '2026-05-03 00:08:15.231693', '2026-05-03 10:08:21.01533', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (95, 64, 'asdasdas', 'server', '', '{"x": 375.93638643345577, "y": 147.43519299859028}', 'active', '', 'internal', '', 12, '2026-05-03 00:11:48.47406', '2026-05-03 00:11:48.47406', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (98, 67, 'WST5SI1 1', 'server', '', '{"x": 103.10663146626369, "y": 214.90037364052037}', 'active', '', 'internal', '', 33, '2026-05-03 00:26:07.375637', '2026-05-03 11:32:48.953817', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (84, 49, 'Permisson', 'server', '', '{"x": 110.9580844483482, "y": 116.58644470113214}', 'active', '', 'internal', '', 30, '2026-04-22 10:47:50.362594', '2026-05-05 10:11:06.024184', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (85, 47, 'Gateway', 'server', '', '{"x": 313.67037515628283, "y": 162.1380995352837}', 'active', '', 'internal', '', 30, '2026-04-22 10:48:06.585766', '2026-05-05 10:11:21.426345', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (91, 50, 'DB_GATEWAY', 'database', '', '{"x": 446.68783176356385, "y": -5.0566922328260375}', 'active', '', 'internal', '', 30, '2026-04-27 08:16:49.585207', '2026-05-05 10:14:08.892336', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (92, 50, 'DB_PERMISSON', 'database', '', '{"x": 196.42704383409756, "y": -6.195245120935908}', 'active', '', 'internal', '', 30, '2026-04-27 08:18:56.971915', '2026-05-05 10:14:08.895482', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (93, 48, 'CONTAINER_INQUIRY', 'application_server', '', '{"x": -5.104655811326666, "y": 87.20901955879225}', 'active', '', 'internal', '', 30, '2026-04-27 08:21:22.254462', '2026-05-05 08:38:42.932708', NULL, NULL, '', NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 5404 (class 0 OID 30695)
-- Dependencies: 249
-- Data for Name: service_to_service_connections; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5392 (class 0 OID 30615)
-- Dependencies: 236
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (11, 327, 'Docker', 'active', 'upload', '/uploads/cmdb-1770604802657-199219102.png', NULL, NULL, '2026-02-09 09:40:02.458284', '2026-02-09 16:54:46.160463', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (12, 327, 'Docker', 'active', 'upload', '/uploads/cmdb-1770604932566-70953586.png', NULL, NULL, '2026-02-09 09:42:12.500267', '2026-02-09 16:54:46.384394', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (13, 327, 'Docker', 'active', 'upload', '/uploads/cmdb-1770604932600-159032111.png', NULL, NULL, '2026-02-09 09:42:12.59065', '2026-02-09 16:54:46.43941', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (18, 329, 'DB Gate', 'active', 'preset', NULL, 'postgresql', NULL, '2026-02-09 09:56:52.435903', '2026-02-09 16:54:53.881397', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (9, 21, 'Citrix', 'active', 'upload', '/uploads/cmdb-1770368583862-684257313.png', NULL, NULL, '2026-02-06 16:03:03.256246', '2026-02-06 16:55:26.877487', 1, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (10, 21, 'SQL Server', 'active', 'upload', '/uploads/cmdb-1770371727521-64853617.png', NULL, NULL, '2026-02-06 16:55:27.48492', '2026-02-06 16:55:27.538702', 1, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (15, 328, 'GSS', 'active', 'preset', NULL, 'citrix', NULL, '2026-02-09 09:51:41.499876', '2026-02-09 09:53:22.374318', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (16, 328, 'API', 'active', 'upload', '/uploads/cmdb-1770605530191-719846762.webp', NULL, NULL, '2026-02-09 09:52:10.176338', '2026-02-09 09:53:22.606715', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (17, 328, 'PORTAL', 'active', 'preset', NULL, 'citrix', NULL, '2026-02-09 09:53:22.685562', '2026-02-09 09:53:22.685562', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (19, 330, 'DB', 'active', 'preset', NULL, 'postgresql', NULL, '2026-02-09 09:57:46.986986', '2026-02-09 09:58:02.172263', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (20, 331, 'Web', 'active', 'preset', NULL, 'internet', NULL, '2026-02-09 10:34:39.405424', '2026-02-09 10:36:02.931679', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (21, 332, 'DB', 'active', 'preset', NULL, 'postgresql', NULL, '2026-02-09 10:35:19.865304', '2026-02-09 10:36:08.480507', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (22, 341, 'PSQL', 'active', 'upload', '/uploads/cmdb-1772157649924-152810675.png', NULL, NULL, '2026-02-27 09:00:49.691869', '2026-02-27 09:19:14.372071', 10, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (23, 341, 'Docker', 'active', 'upload', '/uploads/cmdb-1772157712745-708051276.png', NULL, NULL, '2026-02-27 09:01:52.685781', '2026-02-27 09:19:14.603636', 10, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (24, 336, 'SQL Server', 'active', 'upload', '/uploads/cmdb-1772157772820-520641934.png', NULL, NULL, '2026-02-27 09:02:52.614778', '2026-02-27 09:23:48.436947', 10, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (32, 393, 'NextJS', 'active', 'upload', '/uploads/cmdb-1773214356025-139971087.webp', NULL, NULL, '2026-03-11 14:32:35.674705', '2026-03-13 08:07:31.82411', 27, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (34, 213, 'CTH', 'active', 'upload', '/uploads/cmdb-1773289369485-186664796.webp', NULL, NULL, '2026-03-12 11:16:14.635276', '2026-03-12 11:22:49.496388', 10, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (39, 335, 'Oracle', 'active', 'preset', NULL, 'oracle', NULL, '2026-03-13 22:32:30.095009', '2026-03-13 22:32:30.095009', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (38, 342, 'Citrix', 'active', 'preset', NULL, 'postgresql', NULL, '2026-03-13 21:38:35.479154', '2026-03-14 04:31:20.236884', 5, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (42, 450, 'ZZZ', 'active', 'preset', NULL, 'citrix', NULL, '2026-03-31 08:27:19.238601', '2026-03-31 08:27:19.238601', 29, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (46, 397, 'Oracle', 'inactive', 'upload', '/uploads/cmdb-1776761795780-878503159.png', NULL, NULL, '2026-04-21 15:54:03.154065', '2026-04-21 15:56:35.795751', 27, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (37, 395, '.NET', 'active', 'upload', '/uploads/cmdb-1773297652077-255781684.png', NULL, NULL, '2026-03-12 13:40:52.010662', '2026-04-21 15:59:57.681603', 27, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (36, 395, 'NextJS', 'active', 'upload', '/uploads/cmdb-1773297614669-9992140.webp', NULL, NULL, '2026-03-12 13:40:14.610132', '2026-04-21 16:00:13.74037', 27, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (43, 394, 'Backend', 'active', 'upload', '/uploads/cmdb-1775010255853-334693767.webp', NULL, NULL, '2026-04-01 09:24:15.618028', '2026-04-16 14:16:32.824793', 27, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (44, 394, 'Frontend', 'active', 'upload', '/uploads/cmdb-1775010728863-414013957.webp', NULL, NULL, '2026-04-01 09:32:08.790834', '2026-04-16 14:17:33.462585', 27, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (33, 393, '.NET', 'active', 'upload', '/uploads/cmdb-1773214861167-570179837.png', NULL, NULL, '2026-03-11 14:41:00.77037', '2026-04-16 14:19:11.834456', 27, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (31, 392, 'PostgreSQL', 'active', 'upload', '/uploads/cmdb-1773211071627-590990177.webp', NULL, NULL, '2026-03-11 13:37:51.602131', '2026-04-16 14:19:15.026997', 27, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (63, 467, 'WST0S1', 'active', 'preset', NULL, 'citrix', NULL, '2026-04-27 08:02:51.875039', '2026-04-27 08:02:51.875039', 28, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (57, 403, 'SS1', 'active', 'preset', NULL, 'citrix', NULL, '2026-04-23 10:38:01.282726', '2026-04-27 08:06:45.238673', 28, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (58, 403, 'SS2', 'active', 'preset', NULL, 'citrix', NULL, '2026-04-23 10:58:39.988953', '2026-04-27 08:06:45.270184', 28, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (60, 403, 'SS4', 'active', 'preset', NULL, 'citrix', NULL, '2026-04-23 10:58:58.957537', '2026-04-27 08:06:45.756535', 28, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (48, 463, 'Java', 'active', 'upload', '/uploads/cmdb-1776829561827-206502543.png', NULL, NULL, '2026-04-22 10:46:01.693836', '2026-04-29 08:40:47.941349', 30, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (59, 403, 'SS3', 'active', 'preset', NULL, 'citrix', NULL, '2026-04-23 10:58:48.467312', '2026-05-02 23:58:10.913234', 28, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (56, 402, 'TGIS1', 'active', 'preset', NULL, 'citrix', NULL, '2026-04-23 10:10:23.484302', '2026-05-02 23:58:15.535545', 28, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (64, 472, 'asdasdasdasd', 'active', 'preset', NULL, 'citrix', NULL, '2026-05-03 00:11:44.422121', '2026-05-03 00:11:44.422121', 12, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (67, 479, 'WST5S1 1', 'active', 'preset', NULL, 'citrix', NULL, '2026-05-03 00:25:52.503956', '2026-05-03 11:32:50.473188', 33, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (50, 465, 'PostgreSQL', 'active', 'upload', '/uploads/cmdb-1776829648445-550631084.webp', NULL, NULL, '2026-04-22 10:47:28.312368', '2026-05-03 11:41:30.650762', 30, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (49, 464, 'NextJS', 'active', 'upload', '/uploads/cmdb-1776829607780-906794231.webp', NULL, NULL, '2026-04-22 10:46:47.737864', '2026-05-05 10:10:57.507149', 30, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at, workspace_id, "position", width, height, is_expanded) VALUES (47, 462, 'NextJS', 'active', 'upload', '/uploads/cmdb-1776829519480-540085703.webp', NULL, NULL, '2026-04-22 10:45:19.308828', '2026-05-05 10:11:25.810165', 30, '{"x": 0, "y": 0}', 120, 80, false) ON CONFLICT DO NOTHING;


--
-- TOC entry 5407 (class 0 OID 30713)
-- Dependencies: 252
-- Data for Name: share_access_logs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (238, 32, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 08:17:06.505333') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (278, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 09:54:56.157712') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (281, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 09:55:21.200295') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (284, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:05:13.181927') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (287, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:05:41.511926') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (290, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:08:45.795857') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (129, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-26 11:04:03.096441') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (130, 17, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-27 10:43:35.118278') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (292, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:08:45.96166') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (294, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:10:11.119814') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (297, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:11:40.933045') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (300, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:13:34.435361') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (303, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:14:41.128718') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (306, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:26:27.006698') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (309, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:28:49.594813') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (312, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:31:20.115147') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (315, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:32:17.548334') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (318, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:32:23.150365') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (321, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:37:15.401442') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (324, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:38:05.854632') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (128, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-26 11:04:02.789575') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (131, 17, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-27 10:43:35.420172') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (86, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:20:59.127154') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (87, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:20:59.32023') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (88, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:21:40.793559') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (89, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:21:40.95863') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (132, 17, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-03-05 20:11:04.52478') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (133, 17, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-03-05 20:11:04.679673') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (136, 21, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', '2026-03-31 10:11:37.924345') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (137, 21, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', '2026-03-31 10:11:38.248714') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (138, 21, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', '2026-03-31 10:11:52.129602') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (139, 21, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', '2026-03-31 10:11:52.303988') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (140, 22, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-04-25 12:48:25.618644') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (141, 22, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-04-25 12:48:25.707393') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (239, 32, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 08:17:06.830891') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (276, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 09:51:53.038588') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (279, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 09:54:56.169595') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (282, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:04:26.647445') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (285, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:05:13.32462') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (288, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:08:17.440089') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (291, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:08:45.93251') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (295, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:10:19.458745') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (298, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:11:41.16353') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (301, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:14:13.898357') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (304, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:14:41.427874') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (307, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:27:50.25919') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (310, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:28:49.632491') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (313, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:31:54.947636') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (316, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:32:17.801758') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (319, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:32:48.696673') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (322, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:37:37.710678') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (325, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:38:22.43346') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (277, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 09:51:53.440167') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (280, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 09:55:21.173715') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (283, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:04:26.969924') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (286, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:05:41.230987') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (289, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:08:17.619756') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (293, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:10:10.814751') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (296, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:10:19.47369') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (299, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:13:34.173178') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (302, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:14:14.097135') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (305, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:26:26.995658') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (308, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:27:50.790667') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (311, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:31:19.730412') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (314, 39, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:31:54.962386') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (317, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:32:23.062225') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (320, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:32:49.01913') ON CONFLICT DO NOTHING;
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (323, 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '2026-05-05 10:37:58.335886') ON CONFLICT DO NOTHING;


--
-- TOC entry 5409 (class 0 OID 30722)
-- Dependencies: 254
-- Data for Name: share_links; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata, service_id, cmdb_item_id) VALUES (15, 'HF66W8ZN', 5, 1889, '2026-02-24 08:20:53.513301', NULL, true, 6, NULL, '2026-02-26 11:04:03.096441', '{}', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata, service_id, cmdb_item_id) VALUES (17, 'EQYLZGDV', 10, 1889, '2026-02-27 10:43:30.995045', '2026-03-06 10:43:30.984', true, 4, NULL, '2026-03-05 20:11:04.679673', '{}', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata, service_id, cmdb_item_id) VALUES (21, '8N9S4746', 27, 1889, '2026-03-31 10:11:32.641258', '2026-03-31 11:11:32.638', true, 4, NULL, '2026-03-31 10:11:52.303988', '{}', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata, service_id, cmdb_item_id) VALUES (22, 'B5QJZS73', 28, 1889, '2026-04-25 12:48:23.184613', '2026-04-25 13:48:23.182', true, 2, NULL, '2026-04-25 12:48:25.707393', '{}', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata, service_id, cmdb_item_id) VALUES (32, '5RCZ3E3W', 1, 1889, '2026-05-05 08:17:02.015535', NULL, true, 2, NULL, '2026-05-05 08:17:06.830891', '{}', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata, service_id, cmdb_item_id) VALUES (40, '7RYRVB57', 30, 1889, '2026-05-05 10:12:58.284032', '2026-05-05 11:12:58.198', true, 0, '$2b$10$eMd52fKoZebR4yb7HAtIyueV5J0hMBXL3empS.vqO2da0v0fLx6fS', NULL, '{}', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata, service_id, cmdb_item_id) VALUES (39, 'WYRWHCKR', 30, 1889, '2026-05-05 09:51:45.217741', NULL, true, 33, NULL, '2026-05-05 10:31:54.962386', '{}', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata, service_id, cmdb_item_id) VALUES (41, 'N97G69UK', 30, 1889, '2026-05-05 10:13:29.220113', '2026-05-05 11:13:29.161', true, 17, NULL, '2026-05-05 10:38:22.43346', '{}', NULL, NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 5411 (class 0 OID 30736)
-- Dependencies: 256
-- Data for Name: workspaces; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (11, 'Workspace Test 3', 'Workspace Test', false, '2026-01-21 07:58:01.677438', '2026-01-21 07:58:01.677438') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (12, 'Workspace Test 4', 'Workspace Test', false, '2026-01-21 07:58:12.941533', '2026-01-21 07:58:12.941533') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (10, 'Workspace Test 2', 'Workspace Test', false, '2026-01-21 07:57:51.881981', '2026-01-21 08:00:21.923869') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (5, 'Workspace Test 1', 'Workspace Test', false, '2026-01-21 07:56:53.559736', '2026-02-19 08:44:18.510846') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (1, 'Arsitektur Aplikasi TPS', 'Default', true, '2026-01-21 02:08:37.820985', '2026-03-11 10:59:40.172863') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (27, 'TPS', '-', false, '2026-03-11 10:59:57.024447', '2026-03-11 10:59:57.024447') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (28, 'Workspace Test 0', '', false, '2026-03-16 14:06:46.278554', '2026-03-16 14:06:46.278554') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (29, 'Export Import Test', '', false, '2026-03-27 08:17:13.184075', '2026-03-27 08:17:13.184075') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (30, 'TPS 1', '', false, '2026-04-22 10:44:44.999858', '2026-04-22 10:44:44.999858') ON CONFLICT DO NOTHING;
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (33, 'WSTest5', '', false, '2026-05-03 00:24:59.403815', '2026-05-03 00:24:59.403815') ON CONFLICT DO NOTHING;


--
-- TOC entry 5438 (class 0 OID 0)
-- Dependencies: 220
-- Name: cmdb_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cmdb_groups_id_seq', 86, true);


--
-- TOC entry 5439 (class 0 OID 0)
-- Dependencies: 222
-- Name: cmdb_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cmdb_items_id_seq', 483, true);


--
-- TOC entry 5440 (class 0 OID 0)
-- Dependencies: 224
-- Name: connection_type_definitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.connection_type_definitions_id_seq', 33, true);


--
-- TOC entry 5441 (class 0 OID 0)
-- Dependencies: 226
-- Name: connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.connections_id_seq', 406, true);


--
-- TOC entry 5442 (class 0 OID 0)
-- Dependencies: 228
-- Name: cross_service_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cross_service_connections_id_seq', 36, true);


--
-- TOC entry 5443 (class 0 OID 0)
-- Dependencies: 230
-- Name: cross_service_edge_handles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cross_service_edge_handles_id_seq', 81, true);


--
-- TOC entry 5444 (class 0 OID 0)
-- Dependencies: 232
-- Name: edge_handles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.edge_handles_id_seq', 500, true);


--
-- TOC entry 5445 (class 0 OID 0)
-- Dependencies: 234
-- Name: external_item_positions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.external_item_positions_id_seq', 202, true);


--
-- TOC entry 5446 (class 0 OID 0)
-- Dependencies: 239
-- Name: group_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.group_connections_id_seq', 18, true);


--
-- TOC entry 5447 (class 0 OID 0)
-- Dependencies: 241
-- Name: service_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_connections_id_seq', 27, true);


--
-- TOC entry 5448 (class 0 OID 0)
-- Dependencies: 243
-- Name: service_edge_handles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_edge_handles_id_seq', 24, true);


--
-- TOC entry 5449 (class 0 OID 0)
-- Dependencies: 245
-- Name: service_group_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_group_connections_id_seq', 16, true);


--
-- TOC entry 5450 (class 0 OID 0)
-- Dependencies: 247
-- Name: service_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_groups_id_seq', 12, true);


--
-- TOC entry 5451 (class 0 OID 0)
-- Dependencies: 248
-- Name: service_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_items_id_seq', 98, true);


--
-- TOC entry 5452 (class 0 OID 0)
-- Dependencies: 250
-- Name: service_to_service_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_to_service_connections_id_seq', 44, true);


--
-- TOC entry 5453 (class 0 OID 0)
-- Dependencies: 251
-- Name: services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.services_id_seq', 67, true);


--
-- TOC entry 5454 (class 0 OID 0)
-- Dependencies: 253
-- Name: share_access_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.share_access_logs_id_seq', 325, true);


--
-- TOC entry 5455 (class 0 OID 0)
-- Dependencies: 255
-- Name: share_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.share_links_id_seq', 41, true);


--
-- TOC entry 5456 (class 0 OID 0)
-- Dependencies: 257
-- Name: workspaces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.workspaces_id_seq', 33, true);


--
-- TOC entry 5055 (class 2606 OID 30767)
-- Name: cmdb_groups cmdb_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_groups
    ADD CONSTRAINT cmdb_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 5058 (class 2606 OID 30769)
-- Name: cmdb_items cmdb_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_items
    ADD CONSTRAINT cmdb_items_pkey PRIMARY KEY (id);


--
-- TOC entry 5064 (class 2606 OID 30771)
-- Name: connection_type_definitions connection_type_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_type_definitions
    ADD CONSTRAINT connection_type_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 5066 (class 2606 OID 30773)
-- Name: connection_type_definitions connection_type_definitions_type_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_type_definitions
    ADD CONSTRAINT connection_type_definitions_type_slug_key UNIQUE (type_slug);


--
-- TOC entry 5068 (class 2606 OID 30775)
-- Name: connections connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- TOC entry 5070 (class 2606 OID 30777)
-- Name: connections connections_source_id_target_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_id_target_id_key UNIQUE (source_id, target_id);


--
-- TOC entry 5090 (class 2606 OID 30779)
-- Name: cross_service_edge_handles cross_edge_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_service_edge_handles
    ADD CONSTRAINT cross_edge_unique UNIQUE (edge_id, source_service_id, target_service_id, viewing_service_id);


--
-- TOC entry 5082 (class 2606 OID 30781)
-- Name: cross_service_connections cross_service_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_service_connections
    ADD CONSTRAINT cross_service_connections_pkey PRIMARY KEY (id);


--
-- TOC entry 5092 (class 2606 OID 30783)
-- Name: cross_service_edge_handles cross_service_edge_handles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_service_edge_handles
    ADD CONSTRAINT cross_service_edge_handles_pkey PRIMARY KEY (id);


--
-- TOC entry 5084 (class 2606 OID 30785)
-- Name: cross_service_connections cross_service_unique_connection; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_service_connections
    ADD CONSTRAINT cross_service_unique_connection UNIQUE (source_service_item_id, target_service_item_id);


--
-- TOC entry 5097 (class 2606 OID 30787)
-- Name: edge_handles edge_handles_edge_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edge_handles
    ADD CONSTRAINT edge_handles_edge_id_key UNIQUE (edge_id);


--
-- TOC entry 5099 (class 2606 OID 30789)
-- Name: edge_handles edge_handles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edge_handles
    ADD CONSTRAINT edge_handles_pkey PRIMARY KEY (id);


--
-- TOC entry 5103 (class 2606 OID 30791)
-- Name: external_item_positions external_item_positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_item_positions
    ADD CONSTRAINT external_item_positions_pkey PRIMARY KEY (id);


--
-- TOC entry 5105 (class 2606 OID 30793)
-- Name: external_item_positions external_item_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_item_positions
    ADD CONSTRAINT external_item_unique UNIQUE (workspace_id, service_id, external_service_item_id);


--
-- TOC entry 5123 (class 2606 OID 30795)
-- Name: group_connections group_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_pkey PRIMARY KEY (id);


--
-- TOC entry 5125 (class 2606 OID 30797)
-- Name: group_connections group_connections_source_id_target_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_source_id_target_id_key UNIQUE (source_id, target_id);


--
-- TOC entry 5131 (class 2606 OID 30799)
-- Name: service_connections service_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT service_connections_pkey PRIMARY KEY (id);


--
-- TOC entry 5137 (class 2606 OID 30801)
-- Name: service_edge_handles service_edge_handles_edge_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_edge_handles
    ADD CONSTRAINT service_edge_handles_edge_id_key UNIQUE (edge_id);


--
-- TOC entry 5139 (class 2606 OID 30803)
-- Name: service_edge_handles service_edge_handles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_edge_handles
    ADD CONSTRAINT service_edge_handles_pkey PRIMARY KEY (id);


--
-- TOC entry 5148 (class 2606 OID 30805)
-- Name: service_group_connections service_group_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT service_group_connections_pkey PRIMARY KEY (id);


--
-- TOC entry 5154 (class 2606 OID 30807)
-- Name: service_groups service_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_groups
    ADD CONSTRAINT service_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 5115 (class 2606 OID 30809)
-- Name: service_items service_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items
    ADD CONSTRAINT service_items_pkey PRIMARY KEY (id);


--
-- TOC entry 5161 (class 2606 OID 30811)
-- Name: service_to_service_connections service_to_service_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_to_service_connections
    ADD CONSTRAINT service_to_service_connections_pkey PRIMARY KEY (id);


--
-- TOC entry 5121 (class 2606 OID 30813)
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- TOC entry 5164 (class 2606 OID 30815)
-- Name: share_access_logs share_access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_access_logs
    ADD CONSTRAINT share_access_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5171 (class 2606 OID 30817)
-- Name: share_links share_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links
    ADD CONSTRAINT share_links_pkey PRIMARY KEY (id);


--
-- TOC entry 5173 (class 2606 OID 30819)
-- Name: share_links share_links_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links
    ADD CONSTRAINT share_links_token_key UNIQUE (token);


--
-- TOC entry 5133 (class 2606 OID 30821)
-- Name: service_connections unique_service_connection; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT unique_service_connection UNIQUE (service_id, source_id, target_id);


--
-- TOC entry 5175 (class 2606 OID 30823)
-- Name: workspaces workspaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT workspaces_pkey PRIMARY KEY (id);


--
-- TOC entry 5056 (class 1259 OID 30824)
-- Name: idx_cmdb_groups_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_groups_workspace ON public.cmdb_groups USING btree (workspace_id);


--
-- TOC entry 5059 (class 1259 OID 30825)
-- Name: idx_cmdb_items_alias; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_items_alias ON public.cmdb_items USING btree (alias);


--
-- TOC entry 5060 (class 1259 OID 30826)
-- Name: idx_cmdb_items_group_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_items_group_order ON public.cmdb_items USING btree (group_id, order_in_group);


--
-- TOC entry 5061 (class 1259 OID 30827)
-- Name: idx_cmdb_items_port; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_items_port ON public.cmdb_items USING btree (port);


--
-- TOC entry 5062 (class 1259 OID 30828)
-- Name: idx_cmdb_items_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_items_workspace ON public.cmdb_items USING btree (workspace_id);


--
-- TOC entry 5071 (class 1259 OID 30829)
-- Name: idx_connections_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_direction ON public.connections USING btree (direction);


--
-- TOC entry 5072 (class 1259 OID 30830)
-- Name: idx_connections_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_source ON public.connections USING btree (source_id);


--
-- TOC entry 5073 (class 1259 OID 30831)
-- Name: idx_connections_source_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_source_group ON public.connections USING btree (source_group_id);


--
-- TOC entry 5074 (class 1259 OID 30832)
-- Name: idx_connections_source_service_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_source_service_item_id ON public.connections USING btree (source_service_item_id) WHERE (source_service_item_id IS NOT NULL);


--
-- TOC entry 5075 (class 1259 OID 30833)
-- Name: idx_connections_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_target ON public.connections USING btree (target_id);


--
-- TOC entry 5076 (class 1259 OID 30834)
-- Name: idx_connections_target_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_target_service ON public.connections USING btree (target_service_id) WHERE (target_service_id IS NOT NULL);


--
-- TOC entry 5077 (class 1259 OID 30835)
-- Name: idx_connections_target_service_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_target_service_item ON public.connections USING btree (target_service_item_id) WHERE (target_service_item_id IS NOT NULL);


--
-- TOC entry 5078 (class 1259 OID 30836)
-- Name: idx_connections_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_type ON public.connections USING btree (connection_type);


--
-- TOC entry 5079 (class 1259 OID 30837)
-- Name: idx_connections_type_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_type_workspace ON public.connections USING btree (connection_type, workspace_id);


--
-- TOC entry 5080 (class 1259 OID 30838)
-- Name: idx_connections_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_workspace ON public.connections USING btree (workspace_id);


--
-- TOC entry 5093 (class 1259 OID 30839)
-- Name: idx_cross_service_edge_handles_edge; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cross_service_edge_handles_edge ON public.cross_service_edge_handles USING btree (edge_id);


--
-- TOC entry 5094 (class 1259 OID 30840)
-- Name: idx_cross_service_edge_handles_viewing_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cross_service_edge_handles_viewing_service ON public.cross_service_edge_handles USING btree (viewing_service_id, workspace_id) WHERE (viewing_service_id IS NOT NULL);


--
-- TOC entry 5095 (class 1259 OID 30841)
-- Name: idx_cross_service_edge_handles_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cross_service_edge_handles_workspace ON public.cross_service_edge_handles USING btree (workspace_id);


--
-- TOC entry 5085 (class 1259 OID 30842)
-- Name: idx_cross_service_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cross_service_source ON public.cross_service_connections USING btree (source_service_item_id);


--
-- TOC entry 5086 (class 1259 OID 30843)
-- Name: idx_cross_service_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cross_service_target ON public.cross_service_connections USING btree (target_service_item_id);


--
-- TOC entry 5087 (class 1259 OID 30844)
-- Name: idx_cross_service_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cross_service_type ON public.cross_service_connections USING btree (connection_type);


--
-- TOC entry 5088 (class 1259 OID 30845)
-- Name: idx_cross_service_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cross_service_workspace ON public.cross_service_connections USING btree (workspace_id);


--
-- TOC entry 5100 (class 1259 OID 30846)
-- Name: idx_edge_handles_edge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_edge_handles_edge_id ON public.edge_handles USING btree (edge_id);


--
-- TOC entry 5101 (class 1259 OID 30847)
-- Name: idx_edge_handles_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_edge_handles_workspace ON public.edge_handles USING btree (workspace_id);


--
-- TOC entry 5106 (class 1259 OID 30848)
-- Name: idx_external_item_positions_auto_layout; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_item_positions_auto_layout ON public.external_item_positions USING btree (service_id, workspace_id) WHERE (is_auto_layouted = true);


--
-- TOC entry 5107 (class 1259 OID 30849)
-- Name: idx_external_item_positions_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_item_positions_item ON public.external_item_positions USING btree (external_service_item_id);


--
-- TOC entry 5108 (class 1259 OID 30850)
-- Name: idx_external_item_positions_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_item_positions_service ON public.external_item_positions USING btree (service_id);


--
-- TOC entry 5109 (class 1259 OID 30851)
-- Name: idx_external_item_positions_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_item_positions_workspace ON public.external_item_positions USING btree (workspace_id);


--
-- TOC entry 5126 (class 1259 OID 30852)
-- Name: idx_group_connections_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_group_connections_workspace ON public.group_connections USING btree (workspace_id);


--
-- TOC entry 5127 (class 1259 OID 30853)
-- Name: idx_service_conn_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_conn_service ON public.service_connections USING btree (service_id);


--
-- TOC entry 5128 (class 1259 OID 30854)
-- Name: idx_service_conn_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_conn_workspace ON public.service_connections USING btree (workspace_id);


--
-- TOC entry 5129 (class 1259 OID 30855)
-- Name: idx_service_connections_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_connections_type ON public.service_connections USING btree (connection_type);


--
-- TOC entry 5134 (class 1259 OID 30856)
-- Name: idx_service_edge_handles_edge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_edge_handles_edge_id ON public.service_edge_handles USING btree (edge_id);


--
-- TOC entry 5135 (class 1259 OID 30857)
-- Name: idx_service_edge_handles_service_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_edge_handles_service_workspace ON public.service_edge_handles USING btree (service_id, workspace_id);


--
-- TOC entry 5140 (class 1259 OID 30858)
-- Name: idx_service_group_conn_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_service ON public.service_group_connections USING btree (service_id);


--
-- TOC entry 5141 (class 1259 OID 30859)
-- Name: idx_service_group_conn_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_source ON public.service_group_connections USING btree (source_id);


--
-- TOC entry 5142 (class 1259 OID 30860)
-- Name: idx_service_group_conn_source_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_source_group ON public.service_group_connections USING btree (source_group_id);


--
-- TOC entry 5143 (class 1259 OID 30861)
-- Name: idx_service_group_conn_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_target ON public.service_group_connections USING btree (target_id);


--
-- TOC entry 5144 (class 1259 OID 30862)
-- Name: idx_service_group_conn_target_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_target_group ON public.service_group_connections USING btree (target_group_id);


--
-- TOC entry 5145 (class 1259 OID 30863)
-- Name: idx_service_group_conn_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_workspace ON public.service_group_connections USING btree (workspace_id);


--
-- TOC entry 5151 (class 1259 OID 30864)
-- Name: idx_service_groups_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_groups_service ON public.service_groups USING btree (service_id);


--
-- TOC entry 5152 (class 1259 OID 30865)
-- Name: idx_service_groups_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_groups_workspace ON public.service_groups USING btree (workspace_id);


--
-- TOC entry 5110 (class 1259 OID 30866)
-- Name: idx_service_items_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_items_domain ON public.service_items USING btree (domain) WHERE (domain IS NOT NULL);


--
-- TOC entry 5111 (class 1259 OID 30867)
-- Name: idx_service_items_group_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_items_group_order ON public.service_items USING btree (group_id, order_in_group);


--
-- TOC entry 5112 (class 1259 OID 30868)
-- Name: idx_service_items_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_items_service ON public.service_items USING btree (service_id);


--
-- TOC entry 5113 (class 1259 OID 30869)
-- Name: idx_service_items_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_items_workspace ON public.service_items USING btree (workspace_id);


--
-- TOC entry 5116 (class 1259 OID 30870)
-- Name: idx_services_cmdb_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_services_cmdb_item ON public.services USING btree (cmdb_item_id);


--
-- TOC entry 5117 (class 1259 OID 30871)
-- Name: idx_services_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_services_status ON public.services USING btree (status);


--
-- TOC entry 5118 (class 1259 OID 30872)
-- Name: idx_services_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_services_workspace ON public.services USING btree (workspace_id);


--
-- TOC entry 5119 (class 1259 OID 30873)
-- Name: idx_services_workspace_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_services_workspace_item ON public.services USING btree (workspace_id, cmdb_item_id);


--
-- TOC entry 5146 (class 1259 OID 30874)
-- Name: idx_sgc_target_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sgc_target_item ON public.service_group_connections USING btree (target_item_id);


--
-- TOC entry 5162 (class 1259 OID 30875)
-- Name: idx_share_access_logs_link; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_access_logs_link ON public.share_access_logs USING btree (share_link_id);


--
-- TOC entry 5165 (class 1259 OID 30876)
-- Name: idx_share_links_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_links_active ON public.share_links USING btree (is_active, expires_at);


--
-- TOC entry 5166 (class 1259 OID 31128)
-- Name: idx_share_links_cmdb_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_links_cmdb_item_id ON public.share_links USING btree (cmdb_item_id);


--
-- TOC entry 5167 (class 1259 OID 31127)
-- Name: idx_share_links_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_links_service_id ON public.share_links USING btree (service_id);


--
-- TOC entry 5168 (class 1259 OID 30877)
-- Name: idx_share_links_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_links_token ON public.share_links USING btree (token);


--
-- TOC entry 5169 (class 1259 OID 30878)
-- Name: idx_share_links_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_links_workspace ON public.share_links USING btree (workspace_id);


--
-- TOC entry 5155 (class 1259 OID 30879)
-- Name: idx_stsc_cmdb_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stsc_cmdb_item ON public.service_to_service_connections USING btree (cmdb_item_id);


--
-- TOC entry 5156 (class 1259 OID 30880)
-- Name: idx_stsc_services_pair; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stsc_services_pair ON public.service_to_service_connections USING btree (source_service_id, target_service_id);


--
-- TOC entry 5157 (class 1259 OID 30881)
-- Name: idx_stsc_source_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stsc_source_service ON public.service_to_service_connections USING btree (source_service_id);


--
-- TOC entry 5158 (class 1259 OID 30882)
-- Name: idx_stsc_target_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stsc_target_service ON public.service_to_service_connections USING btree (target_service_id);


--
-- TOC entry 5159 (class 1259 OID 30883)
-- Name: idx_stsc_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stsc_workspace ON public.service_to_service_connections USING btree (workspace_id);


--
-- TOC entry 5149 (class 1259 OID 30884)
-- Name: unique_service_group_to_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_service_group_to_group ON public.service_group_connections USING btree (service_id, source_id, target_id) WHERE ((source_id IS NOT NULL) AND (source_group_id IS NULL));


--
-- TOC entry 5150 (class 1259 OID 30885)
-- Name: unique_service_group_to_item; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_service_group_to_item ON public.service_group_connections USING btree (service_id, source_group_id, target_item_id) WHERE ((source_group_id IS NOT NULL) AND (source_id IS NULL) AND (target_item_id IS NOT NULL));


--
-- TOC entry 5226 (class 2620 OID 30886)
-- Name: service_to_service_connections service_to_service_connections_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER service_to_service_connections_updated_at BEFORE UPDATE ON public.service_to_service_connections FOR EACH ROW EXECUTE FUNCTION public.update_service_to_service_connections_updated_at();


--
-- TOC entry 5223 (class 2620 OID 30887)
-- Name: cross_service_connections trigger_update_cross_service_connections_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_cross_service_connections_updated_at BEFORE UPDATE ON public.cross_service_connections FOR EACH ROW EXECUTE FUNCTION public.update_cross_service_connections_updated_at();


--
-- TOC entry 5224 (class 2620 OID 30888)
-- Name: cross_service_edge_handles trigger_update_cross_service_edge_handles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_cross_service_edge_handles_updated_at BEFORE UPDATE ON public.cross_service_edge_handles FOR EACH ROW EXECUTE FUNCTION public.update_cross_service_edge_handles_updated_at();


--
-- TOC entry 5225 (class 2620 OID 30889)
-- Name: external_item_positions trigger_update_external_item_positions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_external_item_positions_updated_at BEFORE UPDATE ON public.external_item_positions FOR EACH ROW EXECUTE FUNCTION public.update_external_item_positions_updated_at();


--
-- TOC entry 5176 (class 2606 OID 30890)
-- Name: cmdb_groups cmdb_groups_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_groups
    ADD CONSTRAINT cmdb_groups_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5177 (class 2606 OID 30895)
-- Name: cmdb_items cmdb_items_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_items
    ADD CONSTRAINT cmdb_items_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.cmdb_groups(id) ON DELETE SET NULL;


--
-- TOC entry 5178 (class 2606 OID 30900)
-- Name: cmdb_items cmdb_items_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_items
    ADD CONSTRAINT cmdb_items_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5179 (class 2606 OID 30905)
-- Name: connections connections_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_group_id_fkey FOREIGN KEY (source_group_id) REFERENCES public.cmdb_groups(id) ON DELETE CASCADE;


--
-- TOC entry 5180 (class 2606 OID 30910)
-- Name: connections connections_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.cmdb_items(id) ON DELETE CASCADE;


--
-- TOC entry 5181 (class 2606 OID 30915)
-- Name: connections connections_source_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_service_id_fkey FOREIGN KEY (source_service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5182 (class 2606 OID 30920)
-- Name: connections connections_source_service_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_service_item_id_fkey FOREIGN KEY (source_service_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5183 (class 2606 OID 30925)
-- Name: connections connections_target_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_target_group_id_fkey FOREIGN KEY (target_group_id) REFERENCES public.cmdb_groups(id) ON DELETE CASCADE;


--
-- TOC entry 5184 (class 2606 OID 30930)
-- Name: connections connections_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.cmdb_items(id) ON DELETE SET NULL;


--
-- TOC entry 5185 (class 2606 OID 30935)
-- Name: connections connections_target_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_target_service_id_fkey FOREIGN KEY (target_service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5186 (class 2606 OID 30940)
-- Name: connections connections_target_service_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_target_service_item_id_fkey FOREIGN KEY (target_service_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5187 (class 2606 OID 30945)
-- Name: connections connections_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5188 (class 2606 OID 30950)
-- Name: cross_service_connections cross_service_source_exists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_service_connections
    ADD CONSTRAINT cross_service_source_exists FOREIGN KEY (source_service_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5189 (class 2606 OID 30955)
-- Name: cross_service_connections cross_service_target_exists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cross_service_connections
    ADD CONSTRAINT cross_service_target_exists FOREIGN KEY (target_service_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5190 (class 2606 OID 30960)
-- Name: edge_handles edge_handles_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edge_handles
    ADD CONSTRAINT edge_handles_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5191 (class 2606 OID 30965)
-- Name: external_item_positions external_item_position_item_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_item_positions
    ADD CONSTRAINT external_item_position_item_fk FOREIGN KEY (external_service_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5192 (class 2606 OID 30970)
-- Name: external_item_positions external_item_position_service_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_item_positions
    ADD CONSTRAINT external_item_position_service_fk FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5220 (class 2606 OID 31122)
-- Name: share_links fk_cmdb_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links
    ADD CONSTRAINT fk_cmdb_item FOREIGN KEY (cmdb_item_id) REFERENCES public.cmdb_items(id) ON DELETE SET NULL;


--
-- TOC entry 5221 (class 2606 OID 31117)
-- Name: share_links fk_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links
    ADD CONSTRAINT fk_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE SET NULL;


--
-- TOC entry 5201 (class 2606 OID 30975)
-- Name: service_connections fk_service_conn_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT fk_service_conn_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5202 (class 2606 OID 30980)
-- Name: service_connections fk_service_conn_source; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT fk_service_conn_source FOREIGN KEY (source_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5203 (class 2606 OID 30985)
-- Name: service_connections fk_service_conn_target; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT fk_service_conn_target FOREIGN KEY (target_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5204 (class 2606 OID 30990)
-- Name: service_connections fk_service_conn_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT fk_service_conn_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5205 (class 2606 OID 30995)
-- Name: service_group_connections fk_service_group_conn_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_service_group_conn_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5206 (class 2606 OID 31000)
-- Name: service_group_connections fk_service_group_conn_source_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_service_group_conn_source_group FOREIGN KEY (source_group_id) REFERENCES public.service_groups(id) ON DELETE CASCADE;


--
-- TOC entry 5207 (class 2606 OID 31005)
-- Name: service_group_connections fk_service_group_conn_target_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_service_group_conn_target_group FOREIGN KEY (target_group_id) REFERENCES public.service_groups(id) ON DELETE CASCADE;


--
-- TOC entry 5208 (class 2606 OID 31010)
-- Name: service_group_connections fk_service_group_conn_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_service_group_conn_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5213 (class 2606 OID 31015)
-- Name: service_groups fk_service_groups_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_groups
    ADD CONSTRAINT fk_service_groups_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5214 (class 2606 OID 31020)
-- Name: service_groups fk_service_groups_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_groups
    ADD CONSTRAINT fk_service_groups_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5193 (class 2606 OID 31025)
-- Name: service_items fk_service_items_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items
    ADD CONSTRAINT fk_service_items_group FOREIGN KEY (group_id) REFERENCES public.service_groups(id) ON DELETE SET NULL;


--
-- TOC entry 5194 (class 2606 OID 31030)
-- Name: service_items fk_service_items_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items
    ADD CONSTRAINT fk_service_items_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5195 (class 2606 OID 31035)
-- Name: service_items fk_service_items_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items
    ADD CONSTRAINT fk_service_items_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5196 (class 2606 OID 31040)
-- Name: services fk_services_cmdb_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT fk_services_cmdb_item FOREIGN KEY (cmdb_item_id) REFERENCES public.cmdb_items(id) ON DELETE CASCADE;


--
-- TOC entry 5197 (class 2606 OID 31045)
-- Name: services fk_services_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT fk_services_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5209 (class 2606 OID 31050)
-- Name: service_group_connections fk_sgc_source_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_sgc_source_group FOREIGN KEY (source_group_id) REFERENCES public.service_groups(id) ON DELETE CASCADE;


--
-- TOC entry 5210 (class 2606 OID 31055)
-- Name: service_group_connections fk_sgc_target_group_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_sgc_target_group_group FOREIGN KEY (target_group_id) REFERENCES public.service_groups(id) ON DELETE CASCADE;


--
-- TOC entry 5211 (class 2606 OID 31060)
-- Name: service_group_connections fk_sgc_target_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_sgc_target_item FOREIGN KEY (target_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5212 (class 2606 OID 31065)
-- Name: service_group_connections fk_sgc_target_item_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_sgc_target_item_item FOREIGN KEY (target_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- TOC entry 5219 (class 2606 OID 31070)
-- Name: share_access_logs fk_share_link; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_access_logs
    ADD CONSTRAINT fk_share_link FOREIGN KEY (share_link_id) REFERENCES public.share_links(id) ON DELETE CASCADE;


--
-- TOC entry 5215 (class 2606 OID 31075)
-- Name: service_to_service_connections fk_stsc_cmdb_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_to_service_connections
    ADD CONSTRAINT fk_stsc_cmdb_item FOREIGN KEY (cmdb_item_id) REFERENCES public.cmdb_items(id) ON DELETE CASCADE;


--
-- TOC entry 5216 (class 2606 OID 31080)
-- Name: service_to_service_connections fk_stsc_source_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_to_service_connections
    ADD CONSTRAINT fk_stsc_source_service FOREIGN KEY (source_service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5217 (class 2606 OID 31085)
-- Name: service_to_service_connections fk_stsc_target_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_to_service_connections
    ADD CONSTRAINT fk_stsc_target_service FOREIGN KEY (target_service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- TOC entry 5218 (class 2606 OID 31090)
-- Name: service_to_service_connections fk_stsc_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_to_service_connections
    ADD CONSTRAINT fk_stsc_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5222 (class 2606 OID 31095)
-- Name: share_links fk_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links
    ADD CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- TOC entry 5198 (class 2606 OID 31100)
-- Name: group_connections group_connections_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.cmdb_groups(id) ON DELETE CASCADE;


--
-- TOC entry 5199 (class 2606 OID 31105)
-- Name: group_connections group_connections_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.cmdb_groups(id) ON DELETE CASCADE;


--
-- TOC entry 5200 (class 2606 OID 31110)
-- Name: group_connections group_connections_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


-- Completed on 2026-05-05 10:40:58

--
-- PostgreSQL database dump complete
--

\unrestrict d8nVYJbCGhjWWyzUg6aVkKbejM4d8KIUm6YTmBZ5kSFwuYqNaMO7xaHa0PgOH6C

