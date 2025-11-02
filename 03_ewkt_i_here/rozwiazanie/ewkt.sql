DROP TABLE IF EXISTS obiekty;

CREATE TABLE IF NOT EXISTS obiekty(
    id serial PRIMARY KEY,
    nazwa text,
    geom geometry
);

-- 1a
INSERT INTO obiekty (nazwa, geom)
VALUES ('obiekt1',
  ST_Collect(ARRAY[
    ST_MakeLine(ST_MakePoint(0,1), ST_MakePoint(1,1)), 
    ST_GeomFromText('CIRCULARSTRING(1 1, 2 0, 3 1)'), 
    ST_GeomFromText('CIRCULARSTRING(3 1, 4 2, 5 1)'),
    ST_MakeLine(ST_MakePoint(5,1), ST_MakePoint(6,1))      
  ])
);

-- 1b
WITH outer_ring AS (
  SELECT ST_MakePolygon(
    ST_LineMerge(ST_Collect(ARRAY[
      ST_MakeLine(ST_MakePoint(10,6), ST_MakePoint(14,6)),
      ST_GeomFromText('CIRCULARSTRING(14 6, 16 4, 14 2)'),
      ST_GeomFromText('CIRCULARSTRING(14 2, 12 0, 10 2)'),
      ST_MakeLine(ST_MakePoint(10,2), ST_MakePoint(10,6))
    ]))
  ) AS geom
),
inner_hole AS (
  SELECT ST_Buffer(ST_MakePoint(12,2), 1) AS geom
)
INSERT INTO obiekty (nazwa, geom)
SELECT 
  'obiekt2',
  ST_Difference(outer_ring.geom, inner_hole.geom)
FROM outer_ring, inner_hole;

-- 1c
INSERT INTO obiekty(nazwa, geom)
VALUES ('obiekt3',
  ST_GeomFromText('POLYGON((7 15, 10 17, 12 13, 7 15))')
);

-- 1d
INSERT INTO obiekty(nazwa, geom)
VALUES ('obiekt4',
  ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)')
);

-- 1e
INSERT INTO obiekty(nazwa, geom)
VALUES ('obiekt5',
  ST_Collect(ARRAY[
    ST_GeomFromText('POINT Z(30 30 59)'),
    ST_GeomFromText('POINT Z(38 32 234)')
  ])
);

-- 1f
INSERT INTO obiekty(nazwa, geom)
VALUES ('obiekt6',
  ST_Collect(ARRAY[
    ST_GeomFromText('LINESTRING(1 1, 3 2)'),
    ST_GeomFromText('POINT(4 2)')
  ])
);

-- 2
SELECT ST_Area(
         ST_Buffer(
           ST_ShortestLine(
             (SELECT geom FROM obiekty WHERE nazwa='obiekt3'),
             (SELECT geom FROM obiekty WHERE nazwa='obiekt4')
           ),
           5
         )
       ) AS pole_powierzchni;

------------------------------------------------------------------------------------

-- 3
UPDATE obiekty
SET geom = ST_MakePolygon(
  ST_AddPoint(geom, ST_StartPoint(geom))
)
WHERE nazwa = 'obiekt4';

------------------------------------------------------------------------------------

-- 4
INSERT INTO obiekty (nazwa, geom)
SELECT 'obiekt7',
       ST_Union(
         (SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'),
         (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')
       );

------------------------------------------------------------------------------------

-- 5
SELECT SUM(ST_Area(ST_Buffer(geom, 5))) AS suma_pol_buforow
FROM obiekty
WHERE NOT ST_HasArc(geom);
