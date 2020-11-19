CREATE TABLE units (
    id serial primary key, 
    name varchar NOT NULL, 
    location varchar NOT NULL, 
    size integer NOT NULL
);

CREATE TABLE afscs (
    identifier char(5) primary key, 
    name varchar
);

CREATE TABLE unit_afscs( 
    id serial PRIMARY KEY, 
    unit_id integer REFERENCES units(id) ON DELETE CASCADE, 
    afsc_id char(5) REFERENCES afscs(identifier) ON DELETE CASCADE,
    UNIQUE (unit_id,afsc_id)
);

CREATE TYPE AggregateUnits AS (
        id integer, 
        name varchar, 
        location varchar, 
        size integer,
        afscs char(5)[]
);

CREATE FUNCTION getUnits() RETURNS SETOF AggregateUnits AS 'SELECT id,name,location,size,afscs from units FULL OUTER JOIN (SELECT unit_id, array_agg(afsc_id) AS afscs FROM unit_afscs GROUP BY unit_id) as afscs ON afscs.unit_id=units.id;'  LANGUAGE SQL;
CREATE FUNCTION getUnit(varchar) RETURNS SETOF AggregateUnits AS 'SELECT id,name,location,size,afscs FROM units FULL OUTER JOIN (SELECT unit_id, array_agg(afsc_id) AS afscs FROM unit_afscs GROUP BY unit_id) as afscs ON afscs.unit_id=units.id WHERE name=$1 LIMIT 1; ' LANGUAGE SQL;
CREATE FUNCTION addAFSC(char(5),varchar) RETURNS void AS 'INSERT INTO afscs (identifier, name) VALUES ($1,$2) ON CONFLICT(identifier) DO NOTHING;' LANGUAGE SQL;
CREATE FUNCTION addAFSCtoUnit(integer,char(5)) RETURNS SETOF unit_afscs AS 'INSERT INTO unit_afscs (unit_id,afsc_id) VALUES ($1,$2) ON CONFLICT (unit_id,afsc_id) DO NOTHING RETURNING *;' LANGUAGE SQL;
CREATE FUNCTION addAFSCtoUnit(varchar,char(5)) RETURNS SETOF unit_afscs AS 'SELECT addAFSCtoUnit((SELECT id FROM units WHERE name=$1 LIMIT 1),$2);' LANGUAGE SQL;
CREATE FUNCTION addAFSCStoUnit(integer,char(5)[]) RETURNS integer AS $func$
    DECLARE i integer := 0;
    BEGIN
        IF $2 IS NOT NULL THEN
            FOR i IN array_lower($2,1)..array_upper($2,1) LOOP
                PERFORM addAFSC($2[i],'');
                PERFORM addAFSCtoUnit($1,$2[i]);
            END LOOP;
        END IF;
        RETURN i;
    END
    $func$ LANGUAGE plpgsql;
CREATE FUNCTION addAFSCStoUnit(varchar,char(5)[]) RETURNS integer AS 'SELECT addAFSCStoUnit((SELECT id FROM units WHERE name=$1 LIMIT 1),$2);' LANGUAGE SQL;

CREATE FUNCTION addUnit(varchar,varchar,integer,char(5)[]) RETURNS SETOF AggregateUnits AS $func$
    DECLARE unit units%ROWTYPE;
    BEGIN
        INSERT INTO units (name,location,size) VALUES ($1,$2,$3) RETURNING * INTO unit;
        PERFORM addAFSCStoUnit(unit.id,$4);
        RETURN NEXT getUnit(unit.name);
        RETURN;
    END;
    $func$ LANGUAGE plpgsql;



SELECT addUnit('24NOS','BFE',5,NULL);
SELECT addUnit('194CWS','Seattle, WA',10,array['1b4x4','3d1x1']);


