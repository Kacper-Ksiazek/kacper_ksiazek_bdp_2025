-- 1
SELECT left_table.*
FROM t2019_kar_buildings AS left_table
         LEFT JOIN t2018_kar_buildings AS right_table
                   ON left_table.geometry = right_table.geometry
                       AND left_table."HEIGHT" = right_table."HEIGHT"
WHERE right_table.geometry IS NULL;

-- 2
WITH buildings AS (SELECT left_table.*
                   FROM T2019_KAR_BUILDINGS AS left_table
                            LEFT JOIN T2018_KAR_BUILDINGS AS right_table
                                      ON left_table.geometry = right_table.geometry AND
                                         left_table."HEIGHT" = right_table."HEIGHT"
                   WHERE right_table.geometry IS NULL),
     buffer AS (SELECT ST_Buffer(ST_Union(geometry), 0.005) AS geom
                FROM buildings),
     new_poi AS (SELECT left_table.*
                 FROM T2019_KAR_POI_TABLE AS left_table
                          LEFT JOIN T2018_KAR_POI_TABLE AS right_table
                                    ON left_table.geometry = right_table.geometry
                 WHERE right_table.geometry IS NULL),
     count_poi AS (SELECT COUNT(CASE WHEN ST_Contains(left_table.geom, right_table.geometry) THEN 1 END) AS count,
                          "TYPE"                                                                         as TYPE
                   FROM new_poi AS right_table
                            CROSS JOIN buffer AS left_table
                   GROUP BY TYPE)

SELECT *
FROM count_poi
WHERE count != 0
ORDER BY count DESC;

-- 3
CREATE TABLE streets_reprojected AS
SELECT "ST_NAME",
       "REF_IN_ID",
       "NREF_IN_ID",
       "FUNC_CLASS",
       "SPEED_CAT",
       "FR_SPEED_L",
       "TO_SPEED_L",
       "DIR_TRAVEL",
       ST_Transform(geometry, 3068) AS geom
FROM T2019_KAR_STREETS;

-- 4
CREATE TABLE input_points
(
    id       SERIAL PRIMARY KEY,
    geometry geometry
);

INSERT INTO input_points(geometry)
VALUES ('POINT(8.36093 49.03174)'),
       ('POINT(8.39876 49.00644)');

-- 5
ALTER TABLE input_points
    ALTER COLUMN geometry
        TYPE geometry(Point)
        USING ST_Transform(ST_SetSRID(geometry, 4326), 3068);

-- 6
WITH intersections AS (SELECT "NODE_ID", ST_Transform(geometry, 3068) as geometry
                       FROM T2019_KAR_STREET_NODE AS a
                       WHERE a."INTERSECT" = 'Y'),
     new_line AS (SELECT ST_MakeLine(geometry) AS geometry
                  FROM input_points)
SELECT DISTINCT(left_table.*)
FROM intersections AS left_table
         CROSS JOIN new_line AS right_table
WHERE ST_Contains(ST_Buffer(right_table.geometry, 0.002), left_table.geometry);

-- 7
WITH buffer AS (SELECT ST_Buffer(ST_Union(geometry), 0.003) AS geom
                FROM T2019_KAR_LAND_USE_A
                WHERE "TYPE" ILIKE '%park%'),
     sport_pois AS (SELECT geometry FROM T2019_KAR_POI_TABLE WHERE "TYPE" LIKE 'Sporting Goods Store')
SELECT COUNT(CASE WHEN ST_Contains(left_table.geom, right_table.geometry) THEN 1 END) AS count
FROM sport_pois AS right_table
         CROSS JOIN buffer AS left_table;

-- 8
DROP TABLE T2019_KAR_BRIDGES;

SELECT DISTINCT(ST_Intersection(left_table.geometry, right_table.geometry)) AS geom
INTO T2019_KAR_BRIDGES
FROM T2019_KAR_RAILWAYS AS left_table
         CROSS JOIN T2019_KAR_WATER_LINES AS right_table
WHERE ST_Intersects(left_table.geometry, right_table.geometry);

SELECT * from  T2019_KAR_BRIDGES;