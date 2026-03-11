--
-- PostgreSQL database dump
--

\restrict Yhlc5llDDrzqKKDkfjNRqtNrfXDhMFkDrccpbd3af743guNWFtTMAcaF6lrW2O5

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

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

SET default_table_access_method = heap;

--
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
-- Name: cmdb_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cmdb_groups_id_seq OWNED BY public.cmdb_groups.id;


--
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
-- Name: cmdb_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cmdb_items_id_seq OWNED BY public.cmdb_items.id;


--
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
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
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
-- Name: connection_type_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connection_type_definitions_id_seq OWNED BY public.connection_type_definitions.id;


--
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
    CONSTRAINT check_source_exists CHECK ((((source_id IS NOT NULL) AND (source_group_id IS NULL)) OR ((source_id IS NULL) AND (source_group_id IS NOT NULL)))),
    CONSTRAINT check_target CHECK ((((target_id IS NOT NULL) AND (target_group_id IS NULL)) OR ((target_id IS NULL) AND (target_group_id IS NOT NULL))))
);


--
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
-- Name: connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connections_id_seq OWNED BY public.connections.id;


--
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
-- Name: edge_handles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.edge_handles_id_seq OWNED BY public.edge_handles.id;


--
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
-- Name: group_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_connections_id_seq OWNED BY public.group_connections.id;


--
-- Name: service_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_connections (
    id integer NOT NULL,
    service_id integer NOT NULL,
    source_id integer NOT NULL,
    target_id integer NOT NULL,
    workspace_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
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
-- Name: service_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_connections_id_seq OWNED BY public.service_connections.id;


--
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
-- Name: service_edge_handles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_edge_handles_id_seq OWNED BY public.service_edge_handles.id;


--
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
-- Name: service_group_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_group_connections_id_seq OWNED BY public.service_group_connections.id;


--
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
-- Name: service_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_groups_id_seq OWNED BY public.service_groups.id;


--
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
-- Name: service_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_items_id_seq OWNED BY public.service_items.id;


--
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
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
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
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
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
-- Name: share_access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.share_access_logs_id_seq OWNED BY public.share_access_logs.id;


--
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
    metadata jsonb DEFAULT '{}'::jsonb
);


--
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
-- Name: share_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.share_links_id_seq OWNED BY public.share_links.id;


--
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
-- Name: workspaces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workspaces_id_seq OWNED BY public.workspaces.id;


--
-- Name: cmdb_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_groups ALTER COLUMN id SET DEFAULT nextval('public.cmdb_groups_id_seq'::regclass);


--
-- Name: cmdb_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_items ALTER COLUMN id SET DEFAULT nextval('public.cmdb_items_id_seq'::regclass);


--
-- Name: connection_type_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_type_definitions ALTER COLUMN id SET DEFAULT nextval('public.connection_type_definitions_id_seq'::regclass);


--
-- Name: connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections ALTER COLUMN id SET DEFAULT nextval('public.connections_id_seq'::regclass);


--
-- Name: edge_handles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edge_handles ALTER COLUMN id SET DEFAULT nextval('public.edge_handles_id_seq'::regclass);


--
-- Name: group_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections ALTER COLUMN id SET DEFAULT nextval('public.group_connections_id_seq'::regclass);


--
-- Name: service_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections ALTER COLUMN id SET DEFAULT nextval('public.service_connections_id_seq'::regclass);


--
-- Name: service_edge_handles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_edge_handles ALTER COLUMN id SET DEFAULT nextval('public.service_edge_handles_id_seq'::regclass);


--
-- Name: service_group_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections ALTER COLUMN id SET DEFAULT nextval('public.service_group_connections_id_seq'::regclass);


--
-- Name: service_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_groups ALTER COLUMN id SET DEFAULT nextval('public.service_groups_id_seq'::regclass);


--
-- Name: service_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items ALTER COLUMN id SET DEFAULT nextval('public.service_items_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: share_access_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_access_logs ALTER COLUMN id SET DEFAULT nextval('public.share_access_logs_id_seq'::regclass);


--
-- Name: share_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links ALTER COLUMN id SET DEFAULT nextval('public.share_links_id_seq'::regclass);


--
-- Name: workspaces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspaces ALTER COLUMN id SET DEFAULT nextval('public.workspaces_id_seq'::regclass);


--
-- Data for Name: cmdb_groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (11, 'PLAN MAXIMO DEVELOPMENT', '', '#d6d6d6', '{"x": 562.1020388235285, "y": -3214.420124760768}', '2025-12-18 09:09:24.621683', 1);
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (7, 'Dynamics AX Production', 'Dynamic AX Ecosystem', '#d6d6d6', '{"x": -1106.348576575209, "y": -3915.6916477449163}', '2025-12-17 14:37:51.72339', 1);
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (18, 'SQL SERVER PRODUCTION', '', '#d6d6d6', '{"x": -1311.0547906510508, "y": -3461.52667906644}', '2026-01-06 06:34:18.687279', 1);
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (67, 'Citrix', '', '#c7c7c7', '{"x": -67.25786258575897, "y": -4453.555885803121}', '2026-02-03 09:04:29.376804', 1);
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (10, 'Kubernetes Cluster', '', '#cccccc', '{"x": -2045.1829655132747, "y": -3933.954878404761}', '2025-12-17 15:31:56.19422', 1);
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (69, 'TPS WEB', '', '#c9c9c9', '{"x": -441.6257580824085, "y": -754.6594731397225}', '2026-02-09 10:33:29.457976', 5);
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (68, 'TPS HSSE ENV', '', '#c9c9c9', '{"x": -1173.2280064496329, "y": -751.6330752024941}', '2026-02-09 09:30:01.997017', 5);
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (72, 'G1', '', '#e0e7ff', '{"x": 343.03398072715413, "y": -808.8067934309613}', '2026-03-05 20:13:51.814282', 10);
INSERT INTO public.cmdb_groups (id, name, description, color, "position", created_at, workspace_id) VALUES (8, 'Reporting Service', '', '#d6d6d6', '{"x": -612.7609237985744, "y": -3692.7323943344245}', '2025-12-17 14:46:00.352563', 1);


--
-- Data for Name: cmdb_items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (135, 'K8S2 Docker Worker', 'server', '-', '{"x": 290.7773058393324, "y": -3519.9908313640303}', 'active', '192.168.98.250', 'internal', 'CFS', 10, 1, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (136, 'TPSAXAPP03', 'server', '-', '{"x": -633.8460950649908, "y": -3817.0973967099944}', 'active', '192.168.146.21', 'internal', 'Dermaga', 7, 2, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (50, 'TPSEC', 'server', '-', '{"x": 830.6733657119155, "y": -3921.9524732356895}', 'active', '192.168.46.45', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (10, 'TPSAXAPP01', 'server', '-', '{"x": -985.2655728233144, "y": -3819.5817642261754}', 'active', '192.168.96.33', 'internal', '', 7, 0, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (138, 'TPSPDS02', 'server', '-', '{"x": 1037.2706511417243, "y": -3692.507065320161}', 'active', '192.168.179.223', 'internal', 'CFS', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (66, 'TPSCTXVPX', 'workstation', 'firewall unit number 66', '{"x": -266.9879356101867, "y": -4308.852473623259}', 'active', '192.168.253.66', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (36, 'TPSH2H02', 'server', '-', '{"x": 319.707089619316, "y": -2823.4917036960433}', 'active', '192.168.93.176', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (1, 'TPSBILL01', 'server', '-', '{"x": -168.07231352085836, "y": -2783.8479618060587}', 'active', '192.168.77.185', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (132, 'VB02', 'server', '-', '{"x": 601.8675150627981, "y": -3426.1575137680315}', 'active', '192.168.146.21', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (18, 'TPSWSAPP', 'server', 'Middleware', '{"x": -1237.7774627444228, "y": -2793.3190452177446}', 'active', '192.168.183.174', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (23, 'TPSDBWEB', 'server', 'SQL SERVER', '{"x": 809.2707279253284, "y": -4279.26442790833}', 'active', '192.168.179.223', 'internal', 'Gedung Baru', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (27, 'VB03', 'server', '-', '{"x": 774.6449633345467, "y": -3426.2335571719736}', 'active', '192.168.188.109', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (31, 'TPSVMAXIMO02', 'server', 'CRON & MIF
SERVER', '{"x": -818.9180501334497, "y": -2763.193377865898}', 'active', '192.168.86.220', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (49, 'APPTOS01', 'server', '-', '{"x": 421.3297441385457, "y": -3922.2371186416312}', 'active', '192.168.58.37', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (128, 'TPSMAXIMODEV02', 'server', '-', '{"x": -355.9605747606204, "y": -3070.8656367386466}', 'active', '192.168.155.574', 'internal', '', 11, 1, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (16, 'TPSAXDB02', 'database', '-', '{"x": -796.1677410989014, "y": -3627.1646755004967}', 'active', '192.168.130.170', 'internal', '', 18, 1, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (5, 'VB04', 'server', '-', '{"x": 946.9886862345692, "y": -3427.557805452265}', 'active', '192.168.73.187', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (41, 'VB05', 'server', '-', '{"x": 1113.501997220478, "y": -3428.1028066015647}', 'active', '192.168.180.250', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (14, 'TPSADBX', 'server', 'SQL SERVER DEVELOPMENT', '{"x": -782.4216315725849, "y": -2961.7506473913836}', 'active', '192.168.110.175', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (71, 'TPSISO', 'server', 'ISO', '{"x": 1540.5793749131776, "y": -4243.073741547727}', 'active', '192.168.68.98', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (12, 'TPSAXDB01', 'database', '-', '{"x": -983.8321581457112, "y": -3628.4480952765803}', 'active', '192.168.167.102', 'internal', '', 18, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (85, 'TPSSQL', 'server', 'SQL SERVER', '{"x": 1467.9340769464814, "y": -3981.5479154804157}', 'active', '192.168.40.63', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (141, 'TPSAXRS01', 'server', 'Server report dynamic ax', '{"x": 400.3585509014064, "y": -2529.6870539060938}', 'active', '172.19.155.95', 'internal', 'Gedung Baru', NULL, 1, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (55, 'APPTOS02', 'server', 'server unit number 55', '{"x": 601.754514915179, "y": -3922.343965304101}', 'active', '192.168.236.220', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (90, 'VB01', 'server', '-', '{"x": 423.90972721755855, "y": -3425.1865200295742}', 'active', '192.168.180.102', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (137, 'TPSAV01', 'workstation', 'KASPERSKY', '{"x": 1361.6239678319773, "y": -4244.77501134421}', 'active', '192.168.179.223', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (13, 'TPSVDBMAXIMO', 'database', 'DB2 PRODUCTION', '{"x": -620.0215819362691, "y": -2762.554072482375}', 'active', '192.168.207.179', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (131, 'Bank Server', 'server', '-', '{"x": 246.70744570998124, "y": -3224.1906285602504}', 'active', '192.168.146.212', 'eksternal', 'Gedung Baru', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (37, 'DBTOS2', 'server', '-', '{"x": 216.131182684355, "y": -3921.5595223486093}', 'active', '192.168.43.35', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (44, 'DBMAXIMO01', 'database', 'DB2 DEVELOPMENT', '{"x": -413.5441521468426, "y": -2763.5404198652727}', 'active', '192.168.165.88', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (45, 'TPSAXRS01', 'server', '-', '{"x": -516.4313210842436, "y": -3626.0287793079924}', 'active', '192.168.202.113', 'internal', '', 8, 0, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (24, 'TPSAXAPPX', 'server', 'DYNAMICS AX DEVELOPMENT', '{"x": -990.4117699402774, "y": -2961.6677303339466}', 'active', '192.168.225.157', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (25, 'TPSMAXIMODEV01', 'server', '', '{"x": -559.1207477387995, "y": -3071.9317725491674}', 'active', '192.168.244.44', 'internal', '', 11, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (11, 'TPSEDI01', 'server', 'switch unit number 11', '{"x": -660.3713143976054, "y": -4275.317932449176}', 'active', '192.168.50.150', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (15, 'VB06', 'server', '-', '{"x": 1282.3265154747246, "y": -3428.4316344987133}', 'active', '192.168.37.127', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (4, 'TPSEDI02', 'server', '-', '{"x": -467.04844233454355, "y": -4305.985620577113}', 'active', '192.168.75.216', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (53, 'TPSSW', 'server', 'IT HELPDESK', '{"x": 1182.3276693001278, "y": -4246.961569573647}', 'active', '192.168.242.234', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (17, 'TPSSHARE', 'server', 'DOCUMENT MANAGEMENT', '{"x": 1035.6515048468602, "y": -3977.0907431931632}', 'active', '192.168.204.38', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (6, 'TPSBILL02', 'server', '-', '{"x": 43.57393724479401, "y": -2756.91724181054}', 'active', '192.168.224.107', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (139, 'TPSAXDB01', 'database', 'Server Database Dynamic AX 01', '{"x": 602.6528152408985, "y": -2794.904273653363}', 'active', '172.19.155.51', 'eksternal', 'Gedung Baru', NULL, 0, 'virtual', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (63, 'TPSWEB01', 'server', 'database unit number 63', '{"x": -1071.2582081555204, "y": -4232.043182017056}', 'active', '192.168.230.47', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (88, 'TPSAXAPP02', 'server', 'AOS', '{"x": -806.6481598942341, "y": -3816.46406523591}', 'active', '192.168.112.169', 'internal', '', 7, 1, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (140, 'TPSAXAPP01', 'server', 'Server Aplikasi Dynamic AX 01', '{"x": 796.3293777368938, "y": -2530.8847419079075}', 'active', '172.19.155.45', 'internal', 'Gedung Baru', NULL, 2, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (75, 'K8S1 MASTER', 'server', 'server unit number 75', '{"x": 118.73989481127835, "y": -3551.731544182194}', 'active', '192.168.103.150', 'eksternal', 'Dermaga', 10, 0, 'virtual', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (46, 'TPSWEB02', 'server', '-', '{"x": -857.0615131435643, "y": -4201.53351230324}', 'active', '192.168.26.192', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (214, 'WT2 Server2', 'server', '', '{"x": 840.9529491886992, "y": -271.1070056083974}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (82, 'TPSVMAXIMO01', 'server', ' UI & REPORT
SERVER', '{"x": -1015.1388198670294, "y": -2763.5738767312414}', 'active', '192.168.149.148', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (83, 'K8S4 Docker Worker', 'server', 'server unit number 83', '{"x": 721.6838646820923, "y": -3520.0279101374103}', 'active', '192.168.9.139', 'internal', '', 10, 3, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (92, 'K8S3 Docker Worker', 'server', 'firewall unit number 92', '{"x": 506.17967744726235, "y": -3520.4456506338133}', 'active', '192.168.106.144', 'eksternal', '', 10, 2, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (84, 'TPSPROXY', 'switch', 'Proxy', '{"x": 998.5144089990332, "y": -4246.964535615645}', 'active', '192.168.223.27', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (51, 'TPSAXRS02', 'server', 'workstation unit number 51', '{"x": -352.5223118995233, "y": -3627.8256747523874}', 'active', '192.168.41.27', 'internal', '', 8, 1, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (52, 'TPSH2H01', 'server', '-', '{"x": 134.9209778421486, "y": -2940.037697074275}', 'active', '192.168.82.230', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (97, 'TPSDMAX', 'server', 'AX COA LAMA', '{"x": 1722.4787518783096, "y": -4243.841718368561}', 'active', '192.168.139.14', 'internal', '', NULL, NULL, NULL, 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (20, 'TPSPDS01', 'server', 'database unit number 20', '{"x": 1468.6742982571534, "y": -3758.229494435301}', 'active', '192.168.213.91', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (99, 'TPSGATE', 'server', 'GATE SECURITY
PRODUCTION', '{"x": -156.27291906908306, "y": -3925.980601626821}', 'active', '192.168.22.219', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (133, 'TPSPDS03', 'server', '', '{"x": 862.502930128333, "y": -3707.5785828325515}', 'active', '192.168.155.57', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (59, 'TPSCTXAPP01', 'server', 'server unit number 59', '{"x": -13.02124977071864, "y": -4329.210867229895}', 'active', '192.168.140.135', 'internal', '', 67, 1, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (9, 'TPSCTXAPP02', 'server', '-', '{"x": 198.4361584395415, "y": -4300.68718745754}', 'active', '192.168.145.56', 'internal', '', 67, 2, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (57, 'TPSBI', 'server', 'DASHBOARD BI', '{"x": -947.1380865663648, "y": -4396.459593738182}', 'active', '192.168.213.63', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (331, 'TPSWEBAPP', 'server', '', '{"x": -138.80535743459885, "y": -616.8526728761374}', 'active', '', 'internal', '', 69, 0, 'fisik', 5, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (332, 'TPWEBDB', 'server', '', '{"x": 64.41351753240775, "y": -709.9946572360154}', 'active', '', 'internal', '', 69, 0, 'fisik', 5, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (328, 'TPSAPP05', 'server', '', '{"x": -523.7771053263082, "y": -626.1473841692055}', 'active', '', 'internal', '', 68, 1, 'fisik', 5, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (327, 'TPSHSSE', 'server', '', '{"x": -852.8556158421036, "y": -419.17076559481484}', 'active', '', 'internal', '', 68, 0, 'fisik', 5, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (329, 'TPSGATE', 'server', '', '{"x": -361.11988776659945, "y": -662.7595987608004}', 'active', '', 'internal', '', 68, 3, 'fisik', 5, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (330, 'TPSAPP02', 'server', '', '{"x": -321.95328737491957, "y": -468.8371626751658}', 'active', '', 'internal', '', 68, 2, 'fisik', 5, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (337, 'WT2 2', 'server', '', '{"x": 2178.2472876105767, "y": -616.5783623931675}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (340, 'WT2 5', 'server', '', '{"x": 2926.050259788641, "y": -442.86137653936663}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (336, 'WT2 1', 'database', '', '{"x": 2613.4947071350234, "y": -322.80084190979085}', 'maintenance', '', 'internal', '', NULL, 0, 'fisik', 10, '{"unit": "GB", "used": 230, "total": 512}', NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (21, 'TPSAXAPP', 'server', '[AOS BALANCER]', '{"x": -1480.1713511433175, "y": -3579.782908336422}', 'active', '192.168.0.223', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (29, 'TPSESS', 'server', 'switch unit number 29', '{"x": -1327.2099106185447, "y": -4163.7928791032755}', 'active', '192.168.180.180', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (335, 'WST1 01', 'server', '', '{"x": -888.2924247490752, "y": -1051.3261398063894}', 'active', '', 'internal', '', NULL, 0, 'fisik', 5, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (341, 'WT2 6', 'database', '', '{"x": 2861.5858137859786, "y": -156.0803079490524}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (339, 'WT2 4', 'server', '', '{"x": 2671.3887895625544, "y": -600.5375116496798}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (338, 'WT 3', 'server', '', '{"x": 2408.6735063954106, "y": -481.5590226702338}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (342, 'Test 1', 'server', '', '{"x": -704.7099685608412, "y": -933.7409058860917}', 'active', '', 'internal', '', NULL, 0, 'fisik', 5, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (213, 'WT2 Server1', 'server', '', '{"x": 874.613108128633, "y": -554.9391560181423}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (212, 'WT2 DB2', 'database', '', '{"x": 1170.4328024774354, "y": -262.86241023468915}', 'active', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (100, 'DBTOS1', 'server', '', '{"x": 23.87526764309594, "y": -3921.5743104619087}', 'maintenance', '192.168.195.138', 'internal', '', NULL, NULL, 'fisik', 1, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (211, 'WT2 DB1', 'database', '', '{"x": 1166.7772220507945, "y": -100.94863276582737}', 'inactive', '', 'internal', '', NULL, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (365, 'WT2 ITEM3', 'server', '', '{"x": 415.9950434170354, "y": -601.257028834394}', 'active', '', 'internal', '', 72, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (366, 'WT2 TEST3', 'server', '', '{"x": 617.380206914579, "y": -738.9898783083291}', 'active', '', 'internal', '', 72, 0, 'fisik', 10, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (367, 'Citrix', 'server', '', '{"x": 171.26870549019515, "y": -3454.420124760768}', 'active', '172.19.220.24', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'remote.tps.co.id', NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (381, 'Employee Self Service', 'server', '', '{"x": 567.1013967270078, "y": -3032.571511370477}', 'active', '172.19.154.99', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'ess.tps.co.id', 86);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (369, 'Clique', 'server', '', '{"x": 545.4353721568618, "y": -3456.0867914274345}', 'active', '172.19.162.34', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'clique.tps.co.id', 82);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (382, 'Website Corporate', 'server', '', '{"x": 814.5091299969255, "y": -3033.671101296121}', 'active', '172.19.154.97', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'tps.co.id', 3000);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (371, 'Kantin', 'server', '', '{"x": 172.93537215686177, "y": -3319.420124760768}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'canteen.tps.co.id', 83);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (372, 'Gateway', 'server', '', '{"x": 363.76870549019515, "y": -3321.0867914274345}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'api.tps.co.id', 8484);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (368, 'Clique247', 'server', '', '{"x": 362.1020388235284, "y": -3456.086791427435}', 'active', 'clique247.tps.co.id', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'clique247.tps.co.id', 82);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (373, 'Elektra', 'server', '', '{"x": 546.2687054901952, "y": -3321.920124760768}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'edoc.tps.co.id', 7008);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (370, 'Auth', 'server', '', '{"x": 733.7687054901952, "y": -3456.920124760768}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'auth.tps.co.id', 8484);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (374, 'Elektra', 'server', '', '{"x": 733.768705490195, "y": -3322.7534580941015}', 'active', '172.19.154.42', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'elektra.tps.co.id', 8111);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (375, 'Working Permit', 'server', '', '{"x": 154.60203882352852, "y": -3170.2534580941015}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'gss.tps.co.id', 82);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (377, 'QR Portal', 'server', '', '{"x": 547.1020388235286, "y": -3171.920124760768}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'qr.tps.co.id', 81);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (376, 'Portal TPS', 'server', '', '{"x": 362.93537215686183, "y": -3170.2534580941015}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'portal.tps.co.id', 85);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (378, 'Meeting Room Pengguna', 'server', '', '{"x": 733.7687054901953, "y": -3173.5867914274345}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'room.tps.co.id', 8589);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (379, 'Gateway Dev', 'server', '', '{"x": 170.14943356949533, "y": -3033.671101296121}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'stock.tps.co.id', 8333);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (380, 'Xray Monitoring', 'server', '', '{"x": 360.37849070592097, "y": -3033.671101296121}', 'active', '172.19.155.50', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'xray.tps.co.id', NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (383, 'My TPS Website', 'server', '', '{"x": 147.05804513096967, "y": -2898.421540441899}', 'active', '172.19.154.95', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'my.tps.co.id', 8333);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (384, 'My TPS Vendor Admin', 'server', '', '{"x": 361.47808063156504, "y": -2897.3219505162556}', 'active', '172.19.154.42', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'vss.tps.co.id', 32005);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (385, 'HSSE For Security', 'server', '', '{"x": 618.7821232322794, "y": -2898.421540441899}', 'active', '172.19.154.41', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'hsse.tps.co.id', 32009);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (386, 'SH TPS', 'server', '', '{"x": 843.0984680636716, "y": -2897.3219505162556}', 'active', '', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'sh.tps.co.id', NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (387, 'Alesys', 'server', '', '{"x": 170.14943356949533, "y": -2758.773619885101}', 'active', '172.19.154.42', 'internal', '', NULL, 0, 'fisik', 27, NULL, 'alesys.tps.co.id/', 8111);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (393, 'TPSAPP05', 'server', '', '{"x": 809.3552850863341, "y": -3721.6650239431797}', 'active', '172.19.155.51', 'internal', '', NULL, 0, 'fisik', 27, NULL, NULL, NULL);
INSERT INTO public.cmdb_items (id, name, type, description, "position", status, ip, category, location, group_id, order_in_group, env_type, workspace_id, storage, alias, port) VALUES (392, 'TPSAPP02', 'database', '', '{"x": 1062.7609569462752, "y": -3456.597934749846}', 'active', '172.19.155.50', 'internal', '', NULL, 0, 'fisik', 27, NULL, NULL, 5432);


--
-- Data for Name: connection_type_definitions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (1, 'depends_on', 'Depends On', 'Source item depends on target item (jika target mati, source terdampak)', 'arrow-up-right', 'forward', '#3b82f6', true, true, '2026-02-26 14:00:30.177742');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (2, 'consumed_by', 'Consumed By', 'Source item is consumed by target item (resource usage)', 'arrow-down-right', 'backward', '#f59e0b', true, true, '2026-02-26 14:00:30.177742');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (3, 'connects_to', 'Connects To', 'Network connection between items', 'link', 'bidirectional', '#8b5cf6', true, true, '2026-02-26 14:00:30.177742');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (4, 'contains', 'Contains', 'Source contains target (parent-child relationship)', 'layers', 'forward', '#10b981', true, true, '2026-02-26 14:00:30.177742');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (5, 'managed_by', 'Managed By', 'Source is managed by target', 'shield', 'backward', '#a855f7', true, true, '2026-02-26 14:00:30.177742');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (6, 'data_flow_to', 'Data Flow To', 'Data flows from source to target', 'trending-up', 'forward', '#06b6d4', true, true, '2026-02-26 14:00:30.177742');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (7, 'backup_to', 'Backup To', 'Source backs up to target', 'refresh-cw', 'forward', '#14b8a6', true, true, '2026-02-26 14:00:30.177742');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (8, 'backed_up_by', 'Backed Up By', 'Source item is backed up by target item', 'refresh-cw', 'backward', '#14b8a6', true, true, '2026-02-26 14:42:56.963282');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (9, 'hosted_on', 'Hosted On', 'Source item is hosted on target item (VM on physical server)', 'server', 'forward', '#6366f1', true, true, '2026-02-26 14:42:56.972995');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (10, 'hosting', 'Hosting', 'Source item hosts target item', 'server', 'backward', '#6366f1', true, true, '2026-02-26 14:42:56.975285');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (11, 'licensed_by', 'Licensed By', 'Source item uses license from target item', 'key', 'backward', '#eab308', true, true, '2026-02-26 14:42:56.977598');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (12, 'licensing', 'Licensing', 'Source item provides license to target item', 'key', 'forward', '#eab308', true, true, '2026-02-26 14:42:56.979709');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (13, 'part_of', 'Part Of', 'Source item is part of target item (component relationship)', 'puzzle', 'forward', '#a855f7', true, true, '2026-02-26 14:42:56.982333');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (14, 'comprised_of', 'Comprised Of', 'Source item is composed of target item', 'puzzle', 'backward', '#a855f7', true, true, '2026-02-26 14:42:56.983539');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (15, 'related_to', 'Related To', 'Source item is related to target item (general relationship)', 'link', 'bidirectional', '#94a3b8', true, true, '2026-02-26 14:42:56.985066');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (16, 'preceding', 'Preceding', 'Source item precedes target item in workflow', 'arrow-up', 'forward', '#f97316', true, true, '2026-02-26 14:42:56.986843');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (17, 'succeeding', 'Succeeding', 'Source item succeeds target item in workflow', 'arrow-down', 'backward', '#f97316', true, true, '2026-02-26 14:42:56.988294');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (18, 'encrypted_by', 'Encrypted By', 'Source item is encrypted by target item', 'lock', 'backward', '#be123c', true, true, '2026-02-26 14:42:56.989695');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (19, 'encrypting', 'Encrypting', 'Source item encrypts target item', 'lock', 'forward', '#be123c', true, true, '2026-02-26 14:42:56.991096');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (20, 'authenticated_by', 'Authenticated By', 'Source item is authenticated by target item', 'shield-check', 'backward', '#059669', true, true, '2026-02-26 14:42:56.992469');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (21, 'authenticating', 'Authenticating', 'Source item authenticates target item', 'shield-check', 'forward', '#059669', true, true, '2026-02-26 14:42:56.993744');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (22, 'monitoring', 'Monitoring', 'Source item monitors target item', 'eye', 'forward', '#ec4899', true, true, '2026-02-26 14:42:56.995511');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (23, 'monitored_by', 'Monitored By', 'Source item is monitored by target item', 'eye', 'backward', '#ec4899', true, true, '2026-02-26 14:42:56.997289');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (24, 'load_balanced_by', 'Load Balanced By', 'Source item is load balanced by target item', 'scale', 'backward', '#8b5cf6', true, true, '2026-02-26 14:42:56.999077');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (25, 'load_balancing', 'Load Balancing', 'Source item load balances target item', 'scale', 'forward', '#8b5cf6', true, true, '2026-02-26 14:42:57.000362');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (26, 'failing_over_to', 'Failing Over To', 'Source item fails over to target item', 'zap', 'forward', '#ef4444', true, true, '2026-02-26 14:42:57.00192');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (27, 'failover_from', 'Failover From', 'Source item is failover source for target item', 'zap', 'backward', '#ef4444', true, true, '2026-02-26 14:42:57.004301');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (28, 'replicating_to', 'Replicating To', 'Source item replicates data to target item', 'database', 'forward', '#06b6d4', true, true, '2026-02-26 14:42:57.005574');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (29, 'replicated_by', 'Replicated By', 'Source item is replicated by target item', 'database', 'backward', '#06b6d4', true, true, '2026-02-26 14:42:57.006931');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (30, 'proxying_for', 'Proxying For', 'Source item proxies requests for target item', 'workflow', 'forward', '#f59e0b', true, true, '2026-02-26 14:42:57.008432');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (31, 'proxied_by', 'Proxied By', 'Source item is proxied by target item', 'workflow', 'backward', '#f59e0b', true, true, '2026-02-26 14:42:57.00959');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (32, 'routed_through', 'Routed Through', 'Source item is routed through target item', 'route', 'forward', '#10b981', true, true, '2026-02-26 14:42:57.011061');
INSERT INTO public.connection_type_definitions (id, type_slug, label, description, icon, default_direction, color, show_arrow, is_active, created_at) VALUES (33, 'routing', 'Routing', 'Source item routes target item', 'route', 'backward', '#10b981', true, true, '2026-02-26 14:42:57.012347');


--
-- Data for Name: connections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (105, 75, 92, '2025-12-18 15:57:03.325009', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (106, 75, 83, '2025-12-18 15:57:03.337364', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (107, 10, 88, '2025-12-18 15:58:25.348392', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (108, 10, 136, '2025-12-18 15:58:25.359345', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (109, 12, 16, '2025-12-18 15:59:20.812268', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (111, 45, 51, '2025-12-18 16:00:15.591658', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (112, 25, 128, '2025-12-18 16:01:25.101922', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (117, 13, 82, '2025-12-31 14:54:03.572744', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (118, 13, 31, '2025-12-31 14:54:03.596248', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (44, 139, 140, '2025-12-17 08:25:16.015548', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (45, 139, 141, '2025-12-17 08:25:31.117264', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (50, 63, 46, '2025-12-17 10:23:49.426594', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (51, 11, 4, '2025-12-17 10:28:31.410621', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (58, 24, 14, '2025-12-17 15:10:28.837987', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (59, 18, 21, '2025-12-17 15:14:43.436497', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (60, 18, 82, '2025-12-17 15:17:27.618368', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (65, 100, 37, '2025-12-18 08:35:04.122403', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (69, 23, 63, '2025-12-18 08:39:20.522592', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (70, 100, 63, '2025-12-18 08:41:02.734992', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (71, 49, 55, '2025-12-18 08:42:19.229062', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (73, 100, 49, '2025-12-18 08:44:11.414446', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (75, 85, 17, '2025-12-18 08:46:41.421655', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (76, 49, 50, '2025-12-18 08:47:33.542173', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (77, 18, 1, '2025-12-18 08:55:11.389724', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (78, 1, 6, '2025-12-18 08:59:21.309456', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (79, 52, 131, '2025-12-18 09:03:11.445612', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (80, 52, 36, '2025-12-18 09:03:31.959673', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (81, 1, 52, '2025-12-18 09:04:23.405868', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (82, 18, 52, '2025-12-18 09:06:24.351491', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (83, 133, 90, '2025-12-18 09:17:04.823468', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (84, 133, 132, '2025-12-18 09:17:04.855033', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (85, 133, 27, '2025-12-18 09:17:04.946953', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (86, 133, 5, '2025-12-18 09:17:04.960284', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (87, 133, 41, '2025-12-18 09:17:04.972706', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (88, 133, 15, '2025-12-18 09:17:04.980099', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (91, 49, 133, '2025-12-18 13:27:01.820702', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (92, 20, 138, '2025-12-18 13:30:52.906541', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (93, 75, 135, '2025-12-18 13:39:01.592', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (126, 1, 18, '2026-01-05 09:40:36.726562', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (231, 336, 341, '2026-02-27 08:55:30.69429', NULL, NULL, 10, 'backed_up_by', 'backward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (232, 336, 340, '2026-02-27 09:21:29.565758', NULL, NULL, 10, 'consumed_by', 'backward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (237, 29, 57, '2026-02-27 09:36:53.619528', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (238, 29, 99, '2026-02-27 09:36:54.224257', NULL, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (239, 29, NULL, '2026-02-27 09:36:55.543233', 10, NULL, 1, 'depends_on', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (242, 337, 338, '2026-02-27 09:41:54.726263', NULL, NULL, 10, 'part_of', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (253, 211, 212, '2026-03-05 18:46:56.01877', NULL, NULL, 10, 'backed_up_by', 'forward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (259, 211, 214, '2026-03-05 19:11:18.481293', NULL, NULL, 10, 'consumed_by', 'backward');
INSERT INTO public.connections (id, source_id, target_id, created_at, target_group_id, source_group_id, workspace_id, connection_type, direction) VALUES (264, 214, 213, '2026-03-05 19:58:59.099359', NULL, NULL, 10, 'connects_to', 'bidirectional');


--
-- Data for Name: edge_handles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (109, 'e170-169', 'source-right', 'target-left', '2026-01-20 08:08:32.454551', '2026-01-20 08:08:39.080239', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (78, 'e29-99', 'source-bottom', 'target-top', '2026-01-02 14:13:15.276464', '2026-01-02 14:13:23.718112', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (79, 'e29-57', 'source-top', 'target-left', '2026-01-02 14:12:48.837476', '2026-01-02 14:13:27.16148', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (80, 'e63-46', 'source-right', 'target-left', '2026-01-02 14:13:51.044416', '2026-01-02 14:13:56.641687', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (81, 'e23-63', 'source-bottom', 'target-bottom', '2026-01-02 14:14:19.652016', '2026-01-02 14:14:19.652016', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (82, 'e100-37', 'source-bottom', 'target-bottom', '2026-01-02 14:15:26.879452', '2026-01-02 14:15:26.879452', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (83, 'e100-63', 'source-top', 'target-bottom', '2026-01-02 14:14:03.113504', '2026-01-02 14:15:40.724184', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (84, 'e100-49', 'source-bottom', 'target-bottom', '2026-01-02 14:15:30.773093', '2026-01-02 14:15:43.599896', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (85, 'e10-136', 'source-right', 'target-bottom', '2026-01-02 14:15:55.055167', '2026-01-02 14:15:55.055167', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (86, 'e11-4', 'source-right', 'target-left', '2026-01-02 14:16:04.087073', '2026-01-02 14:16:06.333116', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (87, 'e48-66', 'source-left', 'target-right', '2026-01-02 14:16:11.9354', '2026-01-02 14:16:14.381967', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (88, 'e48-9', 'source-right', 'target-bottom', '2026-01-02 14:16:20.281089', '2026-01-02 14:16:20.281089', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (89, 'e85-17', 'source-top', 'target-top', '2026-01-02 14:16:27.985222', '2026-01-02 14:16:27.985222', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (90, 'e20-138', 'source-bottom', 'target-bottom', '2026-01-02 14:16:35.568098', '2026-01-02 14:16:35.568098', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (91, 'e49-55', 'source-bottom', 'target-bottom', '2026-01-02 14:16:42.328915', '2026-01-02 14:16:42.328915', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (92, 'e49-50', 'source-bottom', 'target-bottom', '2026-01-02 14:16:44.932811', '2026-01-02 14:16:44.932811', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (93, 'e13-82', 'source-bottom', 'target-bottom', '2026-01-02 14:18:07.509484', '2026-01-02 14:18:07.509484', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (94, 'e13-31', 'source-bottom', 'target-bottom', '2026-01-02 14:18:10.659532', '2026-01-02 14:18:10.659532', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (95, 'e1-6', 'source-bottom', 'target-left', '2026-01-02 14:18:43.727463', '2026-01-02 14:18:43.727463', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (97, 'e18-1', 'source-bottom', 'target-bottom', '2026-01-02 14:18:15.138929', '2026-01-02 14:19:21.174823', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (98, 'e18-82', 'source-bottom', 'target-bottom', '2026-01-02 14:18:05.079066', '2026-01-02 14:19:23.644101', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (99, 'e75-92', 'source-right', 'target-bottom', '2026-01-02 14:19:29.792274', '2026-01-02 14:19:29.792274', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (100, 'e52-131', 'source-top', 'target-top', '2026-01-02 14:20:12.132843', '2026-01-02 14:20:12.132843', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (101, 'e1-52', 'source-bottom', 'target-bottom', '2026-01-02 14:18:27.398266', '2026-01-02 14:20:17.511688', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (102, 'e52-36', 'source-bottom', 'target-left', '2026-01-02 14:18:38.199577', '2026-01-02 14:20:19.550056', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (103, 'e18-52', 'source-bottom', 'target-bottom', '2026-01-02 14:18:24.497389', '2026-01-02 14:20:25.340217', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (104, 'e24-14', 'source-right', 'target-left', '2026-01-02 14:22:09.645056', '2026-01-02 14:22:12.580145', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (105, 'group-e7-9', 'source-bottom', 'target-top', '2026-01-05 16:26:03.088024', '2026-01-05 16:26:06.18634', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (106, 'group-e7-8', 'source-bottom', 'target-top', '2026-01-05 16:25:34.464373', '2026-01-05 16:26:09.346589', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (107, 'e29-group10', 'source-left', 'target-top', '2026-01-05 16:26:23.267144', '2026-01-05 16:26:23.267144', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (108, 'e1-18', 'source-bottom', 'target-bottom', '2026-01-19 07:32:51.923639', '2026-01-19 07:32:51.923639', 1);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (177, 'e213-211', 'source-right', 'target-left', '2026-02-26 14:18:52.772725', '2026-02-26 14:18:56.996192', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (184, 'e213-212', 'source-bottom', 'target-top', '2026-02-27 08:29:26.517204', '2026-02-27 08:29:35.508256', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (187, 'e336-341', 'source-right', 'target-top', '2026-02-27 09:18:10.834161', '2026-02-27 09:18:50.975846', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (194, 'e336-340', 'source-top', 'target-left', '2026-02-27 09:21:34.080121', '2026-02-27 09:21:42.470414', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (196, 'e337-338', 'source-bottom', 'target-left', '2026-03-05 08:57:06.519', '2026-03-05 08:57:06.519', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (179, 'e211-214', 'source-bottom', 'target-bottom', '2026-02-26 14:23:38.336683', '2026-03-05 17:51:36.541975', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (202, 'e213-214', 'source-left', 'target-top', '2026-03-05 17:55:37.120485', '2026-03-05 17:55:37.120485', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (203, 'e212-211', 'source-left', 'target-right', '2026-03-05 17:58:12.017732', '2026-03-05 17:58:14.115562', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (205, 'e212-214', 'source-left', 'target-right', '2026-03-05 18:00:46.309958', '2026-03-05 18:00:57.600789', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (207, 'e214-211', 'source-bottom', 'target-left', '2026-03-05 18:43:27.957205', '2026-03-05 18:43:27.957205', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (180, 'e211-212', 'source-right', 'target-right', '2026-02-26 14:32:39.299392', '2026-03-05 18:47:51.528948', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (210, 'e365-214', 'source-bottom', 'target-left', '2026-03-05 20:16:37.012182', '2026-03-05 20:16:37.012182', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (199, 'e214-213', 'source-top', 'target-bottom', '2026-03-05 17:51:30.305902', '2026-03-05 21:08:55.41004', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (212, 'group72-e213', 'source-right', 'target-top', '2026-03-05 21:08:57.027289', '2026-03-05 21:08:57.027289', 10);
INSERT INTO public.edge_handles (id, edge_id, source_handle, target_handle, created_at, updated_at, workspace_id) VALUES (96, 'e18-21', 'source-top', 'target-bottom', '2026-01-02 14:18:50.664474', '2026-03-11 10:50:08.148217', 1);


--
-- Data for Name: group_connections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.group_connections (id, source_id, target_id, created_at, workspace_id, connection_type, direction) VALUES (5, 7, 8, '2025-12-17 15:00:31.367842', 1, 'depends_on', 'forward');
INSERT INTO public.group_connections (id, source_id, target_id, created_at, workspace_id, connection_type, direction) VALUES (10, 7, 18, '2026-01-06 06:38:43.171011', 1, 'depends_on', 'forward');
INSERT INTO public.group_connections (id, source_id, target_id, created_at, workspace_id, connection_type, direction) VALUES (11, 18, 8, '2026-01-06 06:39:00.226361', 1, 'depends_on', 'forward');


--
-- Data for Name: service_connections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.service_connections (id, service_id, source_id, target_id, workspace_id, created_at) VALUES (11, 12, 17, 16, 5, '2026-02-18 11:33:45.799815');
INSERT INTO public.service_connections (id, service_id, source_id, target_id, workspace_id, created_at) VALUES (13, 19, 25, 19, 5, '2026-02-18 16:14:41.318574');
INSERT INTO public.service_connections (id, service_id, source_id, target_id, workspace_id, created_at) VALUES (14, 19, 23, 22, 5, '2026-02-19 08:48:01.118749');
INSERT INTO public.service_connections (id, service_id, source_id, target_id, workspace_id, created_at) VALUES (15, 19, 23, 21, 5, '2026-02-19 08:48:01.142032');
INSERT INTO public.service_connections (id, service_id, source_id, target_id, workspace_id, created_at) VALUES (16, 19, 23, 20, 5, '2026-02-19 08:48:01.222204');


--
-- Data for Name: service_edge_handles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (7, 'service-group-e1-3', 'source-top', 'target-left', 11, 5, '2026-02-18 11:04:45.680949', '2026-02-18 11:04:58.619476');
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (1, 'e13-12', 'source-left', 'target-top', 11, 5, '2026-02-10 09:47:40.827586', '2026-02-18 11:05:09.373918');
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (10, 'e25-19', 'source-top', 'target-left', 19, 5, '2026-02-18 16:14:49.02613', '2026-02-19 08:25:46.303272');
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (16, 'e23-20', 'source-right', 'target-bottom', 19, 5, '2026-02-19 08:48:27.706042', '2026-02-19 08:48:27.706042');
INSERT INTO public.service_edge_handles (id, edge_id, source_handle, target_handle, service_id, workspace_id, created_at, updated_at) VALUES (15, 'e23-21', 'source-right', 'target-bottom', 19, 5, '2026-02-19 08:48:12.708552', '2026-02-25 11:22:38.350079');


--
-- Data for Name: service_group_connections; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: service_groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.service_groups (id, service_id, name, description, color, "position", created_at, workspace_id) VALUES (2, 9, 'Group 1', '', '#e0e7ff', '{"x": 42.91413033517073, "y": 90.69223230920223}', '2026-02-18 09:12:47.94676', 1);
INSERT INTO public.service_groups (id, service_id, name, description, color, "position", created_at, workspace_id) VALUES (5, 19, 'G1', '', '#e0e7ff', '{"x": -26.068248250836405, "y": 163.3477296456947}', '2026-02-18 14:49:51.335641', 5);
INSERT INTO public.service_groups (id, service_id, name, description, color, "position", created_at, workspace_id) VALUES (6, 19, 'G2', '', '#e0e7ff', '{"x": 587.0645463289022, "y": -35.81795959213662}', '2026-02-18 14:49:56.122666', 5);


--
-- Data for Name: service_items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (10, 9, 'Web', 'server', '', '{"x": 262.4659515087648, "y": 287.518685576054}', 'active', '', 'internal', '', 1, '2026-02-06 16:05:28.205574', '2026-02-09 10:22:02.098067', NULL, 0, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (19, 19, '1', 'server', '', '{"x": 15, "y": 55}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:12.447289', '2026-02-19 08:48:38.934342', 5, 0, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (20, 19, '2', 'server', '', '{"x": 185, "y": 55}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:15.378402', '2026-02-19 08:48:38.935852', 5, 0, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (25, 19, '7', 'server', '', '{"x": -414.0706891814734, "y": 309.23300092575835}', 'active', '', 'internal', '', 5, '2026-02-18 16:13:31.742778', '2026-02-19 08:48:38.941247', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (23, 19, '5', 'server', '', '{"x": -264.5037375269838, "y": 575.5819274472655}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:20.271443', '2026-02-19 08:48:39.022471', NULL, 1, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (24, 19, '6', 'server', '', '{"x": 568.6693926644159, "y": 416.9095926687139}', 'active', '', 'internal', '', 5, '2026-02-18 16:13:27.005321', '2026-02-19 08:48:39.049175', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (26, 20, '1', 'server', '', '{"x": 168.098736344937, "y": 216.49478865596365}', 'active', '', 'internal', '', 5, '2026-02-24 11:31:59.926917', '2026-02-24 11:32:05.77769', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (22, 19, '4', 'server', '', '{"x": 15, "y": 165}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:19.073516', '2026-02-19 08:48:38.971905', 5, 2, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (21, 19, '3', 'server', '', '{"x": 355, "y": 55}', 'active', '', 'internal', '', 5, '2026-02-18 14:50:17.725485', '2026-02-19 08:48:39.004233', 5, 3, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (15, 12, 'Test 1', 'server', '', '{"x": -8.78520243151354, "y": 332.53011818616653}', 'active', '', 'internal', '', 5, '2026-02-18 11:16:49.147725', '2026-02-26 13:24:00.369541', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (16, 12, 'Test 2', 'server', '', '{"x": 409, "y": 181}', 'active', '', 'internal', '', 5, '2026-02-18 11:17:04.600546', '2026-02-26 13:24:00.370945', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (17, 12, 'Test 3', 'server', '', '{"x": 215.27984619796428, "y": 373.26501111839394}', 'active', '', 'internal', '', 5, '2026-02-18 11:33:30.307396', '2026-02-26 13:24:00.372137', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (18, 12, 'Test 4', 'server', '', '{"x": 790.3900540453832, "y": 233.2659313834792}', 'active', '', 'internal', '', 5, '2026-02-18 11:33:57.963987', '2026-02-26 13:24:00.373279', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (27, 24, '1', 'server', '', '{"x": 9.601042107211066, "y": 91.51961274031143}', 'active', '', 'internal', '', 10, '2026-03-04 14:25:59.931091', '2026-03-04 14:25:59.931091', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (36, 33, 'Working Permit', 'server', '', '{"x": 81.51128987611615, "y": 292.60776949839914}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-11 14:56:38.232323', '2026-03-11 15:00:43.514158', NULL, NULL, 'gss.tps.co.id', 82);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (37, 33, 'Auth', 'server', '', '{"x": 270.8544518259164, "y": 291.1588743211606}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-11 14:59:04.320578', '2026-03-11 15:00:43.517914', NULL, NULL, 'auth.tps.co.id', 8484);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (38, 33, 'Kantin', 'server', '', '{"x": 441.8986331295572, "y": 291.2325799435646}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-11 14:59:34.262604', '2026-03-11 15:00:43.521932', NULL, NULL, 'canteen.tps.co.id', 83);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (39, 33, 'Gateway', 'server', '', '{"x": 636.3917894951849, "y": 290.2640150190643}', 'active', '172.19.155.51', 'internal', '', 27, '2026-03-11 15:00:30.617339', '2026-03-11 15:00:43.680805', NULL, NULL, 'api.tps.co.id', 8484);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (32, 31, 'Elektra Database', 'database', '', '{"x": 678.6170482804557, "y": 55.01332537948815}', 'active', '172.19.155.50', 'internal', '', 27, '2026-03-11 13:38:24.655086', '2026-03-11 13:58:13.628537', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (34, 31, 'Gateway Database', 'database', '', '{"x": 228.59534125367713, "y": 56.85970513139068}', 'active', '172.19.155.50', 'internal', '', 27, '2026-03-11 13:38:55.261448', '2026-03-11 13:58:13.651288', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (35, 31, 'Gateway Database Dev', 'database', '', '{"x": 437.78931214390104, "y": 55.372371913802226}', 'active', '172.19.155.50', 'internal', '', 27, '2026-03-11 13:39:13.494432', '2026-03-11 13:58:13.653604', NULL, NULL, NULL, NULL);
INSERT INTO public.service_items (id, service_id, name, type, description, "position", status, ip, category, location, workspace_id, created_at, updated_at, group_id, order_in_group, domain, port) VALUES (33, 31, 'Kantin Database', 'database', '', '{"x": 27.436272047799093, "y": 57.234800038874255}', 'active', '172.19.155.50', 'internal', '', 27, '2026-03-11 13:38:34.094558', '2026-03-11 13:58:13.658394', NULL, NULL, NULL, NULL);


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (11, 327, 'Docker', 'active', 'upload', '/uploads/cmdb-1770604802657-199219102.png', NULL, NULL, '2026-02-09 09:40:02.458284', '2026-02-09 16:54:46.160463');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (12, 327, 'Docker', 'active', 'upload', '/uploads/cmdb-1770604932566-70953586.png', NULL, NULL, '2026-02-09 09:42:12.500267', '2026-02-09 16:54:46.384394');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (13, 327, 'Docker', 'active', 'upload', '/uploads/cmdb-1770604932600-159032111.png', NULL, NULL, '2026-02-09 09:42:12.59065', '2026-02-09 16:54:46.43941');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (18, 329, 'DB Gate', 'active', 'preset', NULL, 'postgresql', NULL, '2026-02-09 09:56:52.435903', '2026-02-09 16:54:53.881397');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (9, 21, 'Citrix', 'active', 'upload', '/uploads/cmdb-1770368583862-684257313.png', NULL, NULL, '2026-02-06 16:03:03.256246', '2026-02-06 16:55:26.877487');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (10, 21, 'SQL Server', 'active', 'upload', '/uploads/cmdb-1770371727521-64853617.png', NULL, NULL, '2026-02-06 16:55:27.48492', '2026-02-06 16:55:27.538702');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (15, 328, 'GSS', 'active', 'preset', NULL, 'citrix', NULL, '2026-02-09 09:51:41.499876', '2026-02-09 09:53:22.374318');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (16, 328, 'API', 'active', 'upload', '/uploads/cmdb-1770605530191-719846762.webp', NULL, NULL, '2026-02-09 09:52:10.176338', '2026-02-09 09:53:22.606715');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (17, 328, 'PORTAL', 'active', 'preset', NULL, 'citrix', NULL, '2026-02-09 09:53:22.685562', '2026-02-09 09:53:22.685562');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (19, 330, 'DB', 'active', 'preset', NULL, 'postgresql', NULL, '2026-02-09 09:57:46.986986', '2026-02-09 09:58:02.172263');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (20, 331, 'Web', 'active', 'preset', NULL, 'internet', NULL, '2026-02-09 10:34:39.405424', '2026-02-09 10:36:02.931679');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (21, 332, 'DB', 'active', 'preset', NULL, 'postgresql', NULL, '2026-02-09 10:35:19.865304', '2026-02-09 10:36:08.480507');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (22, 341, 'PSQL', 'active', 'upload', '/uploads/cmdb-1772157649924-152810675.png', NULL, NULL, '2026-02-27 09:00:49.691869', '2026-02-27 09:19:14.372071');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (23, 341, 'Docker', 'active', 'upload', '/uploads/cmdb-1772157712745-708051276.png', NULL, NULL, '2026-02-27 09:01:52.685781', '2026-02-27 09:19:14.603636');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (24, 336, 'SQL Server', 'active', 'upload', '/uploads/cmdb-1772157772820-520641934.png', NULL, NULL, '2026-02-27 09:02:52.614778', '2026-02-27 09:23:48.436947');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (31, 392, 'PostgreSQL', 'active', 'upload', '/uploads/cmdb-1773211071627-590990177.webp', NULL, NULL, '2026-03-11 13:37:51.602131', '2026-03-11 14:13:57.548874');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (32, 393, 'NextJS', 'active', 'upload', '/uploads/cmdb-1773214356025-139971087.webp', NULL, NULL, '2026-03-11 14:32:35.674705', '2026-03-11 14:41:00.334645');
INSERT INTO public.services (id, cmdb_item_id, name, status, icon_type, icon_path, icon_name, description, created_at, updated_at) VALUES (33, 393, '.NET', 'active', 'upload', '/uploads/cmdb-1773214861167-570179837.png', NULL, NULL, '2026-03-11 14:41:00.77037', '2026-03-11 14:41:01.177566');


--
-- Data for Name: share_access_logs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (92, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:24:16.886334');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (94, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:25:00.123168');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (96, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:33:10.000012');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (98, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:35:02.497769');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (100, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:38:30.337542');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (102, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:48:55.211392');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (104, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:55:29.391449');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (106, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:55:34.389399');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (108, 16, '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '2026-02-24 08:58:47.510864');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (110, 16, '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '2026-02-24 08:59:04.019194');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (112, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:19:50.678106');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (114, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:23:22.838308');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (116, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:28:17.205611');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (118, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:31:41.880599');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (120, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:31:48.426295');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (122, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:31:59.947622');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (123, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:32:29.475049');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (125, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:41:21.307269');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (127, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-25 10:43:17.79259');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (129, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-26 11:04:03.096441');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (130, 17, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-27 10:43:35.118278');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (93, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:24:34.089392');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (95, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:28:52.831753');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (97, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:35:02.217538');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (99, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:35:25.041462');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (101, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:40:50.32956');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (103, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:55:29.136554');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (105, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:55:34.386792');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (107, 16, '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '2026-02-24 08:58:47.315955');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (109, 16, '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '2026-02-24 08:59:03.999925');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (111, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:19:50.367773');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (113, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:23:22.536218');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (115, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:28:17.199752');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (117, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:30:29.976521');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (119, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:31:46.244885');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (121, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:31:54.445009');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (124, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 11:41:20.995965');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (126, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-25 10:43:17.524861');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (128, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-26 11:04:02.789575');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (131, 17, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-27 10:43:35.420172');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (86, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:20:59.127154');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (87, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:20:59.32023');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (88, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:21:40.793559');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (89, 15, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:21:40.95863');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (90, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:21:59.014498');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (91, 16, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-02-24 08:21:59.297283');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (132, 17, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-03-05 20:11:04.52478');
INSERT INTO public.share_access_logs (id, share_link_id, visitor_ip, visitor_user_agent, accessed_at) VALUES (133, 17, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '2026-03-05 20:11:04.679673');


--
-- Data for Name: share_links; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata) VALUES (16, 'ZT4JJ6TC', 1, 1889, '2026-02-24 08:21:48.703387', NULL, true, 38, NULL, '2026-02-25 10:43:17.79259', '{}');
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata) VALUES (15, 'HF66W8ZN', 5, 1889, '2026-02-24 08:20:53.513301', NULL, true, 6, NULL, '2026-02-26 11:04:03.096441', '{}');
INSERT INTO public.share_links (id, token, workspace_id, created_by, created_at, expires_at, is_active, access_count, password_hash, last_accessed_at, metadata) VALUES (17, 'EQYLZGDV', 10, 1889, '2026-02-27 10:43:30.995045', '2026-03-06 10:43:30.984', true, 4, NULL, '2026-03-05 20:11:04.679673', '{}');


--
-- Data for Name: workspaces; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (11, 'Workspace Test 3', 'Workspace Test', false, '2026-01-21 07:58:01.677438', '2026-01-21 07:58:01.677438');
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (12, 'Workspace Test 4', 'Workspace Test', false, '2026-01-21 07:58:12.941533', '2026-01-21 07:58:12.941533');
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (10, 'Workspace Test 2', 'Workspace Test', false, '2026-01-21 07:57:51.881981', '2026-01-21 08:00:21.923869');
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (5, 'Workspace Test 1', 'Workspace Test', false, '2026-01-21 07:56:53.559736', '2026-02-19 08:44:18.510846');
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (1, 'Arsitektur Aplikasi TPS', 'Default', true, '2026-01-21 02:08:37.820985', '2026-03-11 10:59:40.172863');
INSERT INTO public.workspaces (id, name, description, is_default, created_at, updated_at) VALUES (27, 'TPS', '-', false, '2026-03-11 10:59:57.024447', '2026-03-11 10:59:57.024447');


--
-- Name: cmdb_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cmdb_groups_id_seq', 73, true);


--
-- Name: cmdb_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cmdb_items_id_seq', 393, true);


--
-- Name: connection_type_definitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.connection_type_definitions_id_seq', 33, true);


--
-- Name: connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.connections_id_seq', 273, true);


--
-- Name: edge_handles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.edge_handles_id_seq', 213, true);


--
-- Name: group_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.group_connections_id_seq', 18, true);


--
-- Name: service_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_connections_id_seq', 16, true);


--
-- Name: service_edge_handles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_edge_handles_id_seq', 18, true);


--
-- Name: service_group_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_group_connections_id_seq', 16, true);


--
-- Name: service_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_groups_id_seq', 7, true);


--
-- Name: service_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.service_items_id_seq', 39, true);


--
-- Name: services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.services_id_seq', 33, true);


--
-- Name: share_access_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.share_access_logs_id_seq', 133, true);


--
-- Name: share_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.share_links_id_seq', 17, true);


--
-- Name: workspaces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.workspaces_id_seq', 27, true);


--
-- Name: cmdb_groups cmdb_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_groups
    ADD CONSTRAINT cmdb_groups_pkey PRIMARY KEY (id);


--
-- Name: cmdb_items cmdb_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_items
    ADD CONSTRAINT cmdb_items_pkey PRIMARY KEY (id);


--
-- Name: connection_type_definitions connection_type_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_type_definitions
    ADD CONSTRAINT connection_type_definitions_pkey PRIMARY KEY (id);


--
-- Name: connection_type_definitions connection_type_definitions_type_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_type_definitions
    ADD CONSTRAINT connection_type_definitions_type_slug_key UNIQUE (type_slug);


--
-- Name: connections connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- Name: connections connections_source_id_target_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_id_target_id_key UNIQUE (source_id, target_id);


--
-- Name: edge_handles edge_handles_edge_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edge_handles
    ADD CONSTRAINT edge_handles_edge_id_key UNIQUE (edge_id);


--
-- Name: edge_handles edge_handles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edge_handles
    ADD CONSTRAINT edge_handles_pkey PRIMARY KEY (id);


--
-- Name: group_connections group_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_pkey PRIMARY KEY (id);


--
-- Name: group_connections group_connections_source_id_target_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_source_id_target_id_key UNIQUE (source_id, target_id);


--
-- Name: service_connections service_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT service_connections_pkey PRIMARY KEY (id);


--
-- Name: service_edge_handles service_edge_handles_edge_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_edge_handles
    ADD CONSTRAINT service_edge_handles_edge_id_key UNIQUE (edge_id);


--
-- Name: service_edge_handles service_edge_handles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_edge_handles
    ADD CONSTRAINT service_edge_handles_pkey PRIMARY KEY (id);


--
-- Name: service_group_connections service_group_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT service_group_connections_pkey PRIMARY KEY (id);


--
-- Name: service_groups service_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_groups
    ADD CONSTRAINT service_groups_pkey PRIMARY KEY (id);


--
-- Name: service_items service_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items
    ADD CONSTRAINT service_items_pkey PRIMARY KEY (id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: share_access_logs share_access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_access_logs
    ADD CONSTRAINT share_access_logs_pkey PRIMARY KEY (id);


--
-- Name: share_links share_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links
    ADD CONSTRAINT share_links_pkey PRIMARY KEY (id);


--
-- Name: share_links share_links_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links
    ADD CONSTRAINT share_links_token_key UNIQUE (token);


--
-- Name: service_connections unique_service_connection; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT unique_service_connection UNIQUE (service_id, source_id, target_id);


--
-- Name: workspaces workspaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT workspaces_pkey PRIMARY KEY (id);


--
-- Name: idx_cmdb_groups_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_groups_workspace ON public.cmdb_groups USING btree (workspace_id);


--
-- Name: idx_cmdb_items_alias; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_items_alias ON public.cmdb_items USING btree (alias);


--
-- Name: idx_cmdb_items_group_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_items_group_order ON public.cmdb_items USING btree (group_id, order_in_group);


--
-- Name: idx_cmdb_items_port; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_items_port ON public.cmdb_items USING btree (port);


--
-- Name: idx_cmdb_items_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cmdb_items_workspace ON public.cmdb_items USING btree (workspace_id);


--
-- Name: idx_connections_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_direction ON public.connections USING btree (direction);


--
-- Name: idx_connections_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_source ON public.connections USING btree (source_id);


--
-- Name: idx_connections_source_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_source_group ON public.connections USING btree (source_group_id);


--
-- Name: idx_connections_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_target ON public.connections USING btree (target_id);


--
-- Name: idx_connections_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_type ON public.connections USING btree (connection_type);


--
-- Name: idx_connections_type_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_type_workspace ON public.connections USING btree (connection_type, workspace_id);


--
-- Name: idx_connections_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_workspace ON public.connections USING btree (workspace_id);


--
-- Name: idx_edge_handles_edge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_edge_handles_edge_id ON public.edge_handles USING btree (edge_id);


--
-- Name: idx_edge_handles_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_edge_handles_workspace ON public.edge_handles USING btree (workspace_id);


--
-- Name: idx_group_connections_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_group_connections_workspace ON public.group_connections USING btree (workspace_id);


--
-- Name: idx_service_conn_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_conn_service ON public.service_connections USING btree (service_id);


--
-- Name: idx_service_conn_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_conn_workspace ON public.service_connections USING btree (workspace_id);


--
-- Name: idx_service_edge_handles_edge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_edge_handles_edge_id ON public.service_edge_handles USING btree (edge_id);


--
-- Name: idx_service_edge_handles_service_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_edge_handles_service_workspace ON public.service_edge_handles USING btree (service_id, workspace_id);


--
-- Name: idx_service_group_conn_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_service ON public.service_group_connections USING btree (service_id);


--
-- Name: idx_service_group_conn_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_source ON public.service_group_connections USING btree (source_id);


--
-- Name: idx_service_group_conn_source_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_source_group ON public.service_group_connections USING btree (source_group_id);


--
-- Name: idx_service_group_conn_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_target ON public.service_group_connections USING btree (target_id);


--
-- Name: idx_service_group_conn_target_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_target_group ON public.service_group_connections USING btree (target_group_id);


--
-- Name: idx_service_group_conn_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_group_conn_workspace ON public.service_group_connections USING btree (workspace_id);


--
-- Name: idx_service_groups_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_groups_service ON public.service_groups USING btree (service_id);


--
-- Name: idx_service_groups_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_groups_workspace ON public.service_groups USING btree (workspace_id);


--
-- Name: idx_service_items_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_items_domain ON public.service_items USING btree (domain) WHERE (domain IS NOT NULL);


--
-- Name: idx_service_items_group_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_items_group_order ON public.service_items USING btree (group_id, order_in_group);


--
-- Name: idx_service_items_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_items_service ON public.service_items USING btree (service_id);


--
-- Name: idx_service_items_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_items_workspace ON public.service_items USING btree (workspace_id);


--
-- Name: idx_services_cmdb_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_services_cmdb_item ON public.services USING btree (cmdb_item_id);


--
-- Name: idx_services_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_services_status ON public.services USING btree (status);


--
-- Name: idx_sgc_target_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sgc_target_item ON public.service_group_connections USING btree (target_item_id);


--
-- Name: idx_share_access_logs_link; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_access_logs_link ON public.share_access_logs USING btree (share_link_id);


--
-- Name: idx_share_links_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_links_active ON public.share_links USING btree (is_active, expires_at);


--
-- Name: idx_share_links_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_links_token ON public.share_links USING btree (token);


--
-- Name: idx_share_links_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_share_links_workspace ON public.share_links USING btree (workspace_id);


--
-- Name: unique_service_group_to_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_service_group_to_group ON public.service_group_connections USING btree (service_id, source_id, target_id) WHERE ((source_id IS NOT NULL) AND (source_group_id IS NULL));


--
-- Name: unique_service_group_to_item; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_service_group_to_item ON public.service_group_connections USING btree (service_id, source_group_id, target_item_id) WHERE ((source_group_id IS NOT NULL) AND (source_id IS NULL) AND (target_item_id IS NOT NULL));


--
-- Name: cmdb_groups cmdb_groups_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_groups
    ADD CONSTRAINT cmdb_groups_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: cmdb_items cmdb_items_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_items
    ADD CONSTRAINT cmdb_items_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.cmdb_groups(id) ON DELETE SET NULL;


--
-- Name: cmdb_items cmdb_items_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cmdb_items
    ADD CONSTRAINT cmdb_items_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: connections connections_source_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_group_id_fkey FOREIGN KEY (source_group_id) REFERENCES public.cmdb_groups(id) ON DELETE CASCADE;


--
-- Name: connections connections_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.cmdb_items(id) ON DELETE CASCADE;


--
-- Name: connections connections_target_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_target_group_id_fkey FOREIGN KEY (target_group_id) REFERENCES public.cmdb_groups(id) ON DELETE CASCADE;


--
-- Name: connections connections_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.cmdb_items(id) ON DELETE CASCADE;


--
-- Name: connections connections_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: edge_handles edge_handles_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edge_handles
    ADD CONSTRAINT edge_handles_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: service_connections fk_service_conn_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT fk_service_conn_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: service_connections fk_service_conn_source; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT fk_service_conn_source FOREIGN KEY (source_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- Name: service_connections fk_service_conn_target; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT fk_service_conn_target FOREIGN KEY (target_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- Name: service_connections fk_service_conn_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_connections
    ADD CONSTRAINT fk_service_conn_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: service_group_connections fk_service_group_conn_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_service_group_conn_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: service_group_connections fk_service_group_conn_source_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_service_group_conn_source_group FOREIGN KEY (source_group_id) REFERENCES public.service_groups(id) ON DELETE CASCADE;


--
-- Name: service_group_connections fk_service_group_conn_target_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_service_group_conn_target_group FOREIGN KEY (target_group_id) REFERENCES public.service_groups(id) ON DELETE CASCADE;


--
-- Name: service_group_connections fk_service_group_conn_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_service_group_conn_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: service_groups fk_service_groups_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_groups
    ADD CONSTRAINT fk_service_groups_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: service_groups fk_service_groups_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_groups
    ADD CONSTRAINT fk_service_groups_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: service_items fk_service_items_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items
    ADD CONSTRAINT fk_service_items_group FOREIGN KEY (group_id) REFERENCES public.service_groups(id) ON DELETE SET NULL;


--
-- Name: service_items fk_service_items_service; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items
    ADD CONSTRAINT fk_service_items_service FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: service_items fk_service_items_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_items
    ADD CONSTRAINT fk_service_items_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: services fk_services_cmdb_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT fk_services_cmdb_item FOREIGN KEY (cmdb_item_id) REFERENCES public.cmdb_items(id) ON DELETE CASCADE;


--
-- Name: service_group_connections fk_sgc_source_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_sgc_source_group FOREIGN KEY (source_group_id) REFERENCES public.service_groups(id) ON DELETE CASCADE;


--
-- Name: service_group_connections fk_sgc_target_group_group; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_sgc_target_group_group FOREIGN KEY (target_group_id) REFERENCES public.service_groups(id) ON DELETE CASCADE;


--
-- Name: service_group_connections fk_sgc_target_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_sgc_target_item FOREIGN KEY (target_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- Name: service_group_connections fk_sgc_target_item_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_group_connections
    ADD CONSTRAINT fk_sgc_target_item_item FOREIGN KEY (target_item_id) REFERENCES public.service_items(id) ON DELETE CASCADE;


--
-- Name: share_access_logs fk_share_link; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_access_logs
    ADD CONSTRAINT fk_share_link FOREIGN KEY (share_link_id) REFERENCES public.share_links(id) ON DELETE CASCADE;


--
-- Name: share_links fk_workspace; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_links
    ADD CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: group_connections group_connections_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.cmdb_groups(id) ON DELETE CASCADE;


--
-- Name: group_connections group_connections_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.cmdb_groups(id) ON DELETE CASCADE;


--
-- Name: group_connections group_connections_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_connections
    ADD CONSTRAINT group_connections_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict Yhlc5llDDrzqKKDkfjNRqtNrfXDhMFkDrccpbd3af743guNWFtTMAcaF6lrW2O5

