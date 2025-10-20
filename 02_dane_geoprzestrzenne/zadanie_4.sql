CREATE TABLE buildings
(
    id       SERIAL PRIMARY KEY,
    geometry GEOMETRY(POLYGON),
    name     VARCHAR(255)
);

CREATE TABLE roads
(
    id       SERIAL PRIMARY KEY,
    geometry GEOMETRY(LINESTRING),
    name     VARCHAR(255)
);

CREATE TABLE poi
(
    id       SERIAL PRIMARY KEY,
    geometry GEOMETRY(POINT),
    name     VARCHAR(255)
);
