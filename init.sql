CREATE TABLE units (
    id serial primary key, 
    name varchar NOT NULL, 
    location varchar NOT NULL, 
    size integer NOT NULL
);

CREATE TABLE afscs (
    ident char(5) primary key, 
    name varchar
);

CREATE TABLE unit_afscs( 
    id serial PRIMARY KEY, 
    unit_id integer REFERENCES units(id) ON DELETE CASCADE, 
    afsc_id char(5) REFERENCES afscs(ident) ON DELETE CASCADE
);

INSERT INTO units (name,location) VALUES 
    ('24NOS','BFE'),
    ('194CWS','Seattle, WA');
