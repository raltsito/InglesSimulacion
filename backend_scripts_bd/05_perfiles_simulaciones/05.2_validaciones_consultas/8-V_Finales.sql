SELECT aprobado, COUNT(*) AS total
FROM examenes
GROUP BY aprobado;
/*** Aprobados VS No aprobados ***/