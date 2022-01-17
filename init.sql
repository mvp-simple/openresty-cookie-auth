DROP schema if EXISTS auth CASCADE;

CREATE SCHEMA auth;


DROP TABLE IF EXISTS auth.users;

CREATE TABLE auth.users
(
    id         bigserial NOT NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    deleted_at timestamptz NULL,
    login      text NULL,
    "password" text NULL,
    fio        text NULL,
    CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_auth_users_deleted_at ON auth.users USING btree (deleted_at);
CREATE UNIQUE INDEX idx_auth_users_login ON auth.users USING btree (login);

DROP TABLE IF EXISTS auth.urls;

CREATE TABLE auth.urls
(
    id         bigserial NOT NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    deleted_at timestamptz NULL,
    title      text NULL,
    uri        text NULL,
    CONSTRAINT urls_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_auth_urls_deleted_at ON auth.urls USING btree (deleted_at);

DROP TABLE IF EXISTS auth.roles;

CREATE TABLE auth.roles
(
    id         bigserial NOT NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    deleted_at timestamptz NULL,
    title      text NULL,
    CONSTRAINT roles_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_auth_roles_deleted_at ON auth.roles USING btree (deleted_at);


DROP TABLE IF EXISTS auth.role_groups;

CREATE TABLE auth.role_groups
(
    id         bigserial NOT NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    deleted_at timestamptz NULL,
    title      text NULL,
    CONSTRAINT role_groups_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_auth_role_groups_deleted_at ON auth.role_groups USING btree (deleted_at);

DROP TABLE IF EXISTS auth.cookies;

CREATE TABLE auth.cookies
(
    id         bigserial NOT NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    deleted_at timestamptz NULL,
    cookie_str text NULL,
    user_id    int8 NULL,
    CONSTRAINT cookies_pkey PRIMARY KEY (id),
    CONSTRAINT fk_auth_cookies_user FOREIGN KEY (user_id) REFERENCES auth.users (id)
);
CREATE INDEX idx_auth_cookies_deleted_at ON auth.cookies USING btree (deleted_at);

DROP TABLE IF EXISTS auth.users_role_groups;

CREATE TABLE auth.users_role_groups
(
    user_id       int8 NOT NULL,
    role_group_id int8 NOT NULL,
    CONSTRAINT users_role_groups_pkey PRIMARY KEY (user_id, role_group_id),
    CONSTRAINT fk_auth_users_role_groups_role_group FOREIGN KEY (role_group_id) REFERENCES auth.role_groups (id),
    CONSTRAINT fk_auth_users_role_groups_user FOREIGN KEY (user_id) REFERENCES auth.users (id)
);


DROP TABLE IF EXISTS auth.users_custom_urls;

CREATE TABLE auth.users_custom_urls
(
    user_id int8 NOT NULL,
    url_id  int8 NOT NULL,
    CONSTRAINT users_custom_urls_pkey PRIMARY KEY (user_id, url_id),
    CONSTRAINT fk_auth_users_custom_urls_url FOREIGN KEY (url_id) REFERENCES auth.urls (id),
    CONSTRAINT fk_auth_users_custom_urls_user FOREIGN KEY (user_id) REFERENCES auth.users (id)
);


DROP TABLE IF EXISTS auth.roles_urls;

CREATE TABLE auth.roles_urls
(
    role_id int8 NOT NULL,
    url_id  int8 NOT NULL,
    CONSTRAINT roles_urls_pkey PRIMARY KEY (role_id, url_id),
    CONSTRAINT fk_auth_roles_urls_role FOREIGN KEY (role_id) REFERENCES auth.roles (id),
    CONSTRAINT fk_auth_roles_urls_url FOREIGN KEY (url_id) REFERENCES auth.urls (id)
);


DROP TABLE IF EXISTS auth.role_groups_roles;

CREATE TABLE auth.role_groups_roles
(
    role_group_id int8 NOT NULL,
    role_id       int8 NOT NULL,
    CONSTRAINT role_groups_roles_pkey PRIMARY KEY (role_group_id, role_id),
    CONSTRAINT fk_auth_role_groups_roles_role FOREIGN KEY (role_id) REFERENCES auth.roles (id),
    CONSTRAINT fk_auth_role_groups_roles_role_group FOREIGN KEY (role_group_id) REFERENCES auth.role_groups (id)
);