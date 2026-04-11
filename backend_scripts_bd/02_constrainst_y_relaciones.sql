ALTER TABLE [dbo].[examen_preguntas] ADD  DEFAULT ((0)) FOR [respondida]
ALTER TABLE [dbo].[examen_preguntas] ADD  DEFAULT ((0)) FOR [tiempo_consumido_seg]
ALTER TABLE [dbo].[examen_preguntas] ADD  DEFAULT ((0)) FOR [expiro_tiempo]

ALTER TABLE [dbo].[examenes] ADD  DEFAULT (getdate()) FOR [fecha_inicio]
ALTER TABLE [dbo].[examenes] ADD  DEFAULT ((60)) FOR [tiempo_pregunta_seg]
ALTER TABLE [dbo].[examenes] ADD  DEFAULT ((0)) FOR [aciertos]
ALTER TABLE [dbo].[examenes] ADD  DEFAULT ((0)) FOR [errores]
ALTER TABLE [dbo].[examenes] ADD  CONSTRAINT [DF_examenes_porcentaje]  DEFAULT ((0)) FOR [porcentaje]
ALTER TABLE [dbo].[examenes] ADD  CONSTRAINT [DF_examenes_aprobado]  DEFAULT ((0)) FOR [aprobado]
ALTER TABLE [dbo].[examenes] ADD  DEFAULT ('EnCurso') FOR [estado]

ALTER TABLE [dbo].[historial_estudiante] ADD  DEFAULT (getdate()) FOR [fecha]

ALTER TABLE [dbo].[preguntas] ADD  DEFAULT ('Ingles') FOR [materia]
ALTER TABLE [dbo].[preguntas] ADD  DEFAULT ((1)) FOR [activa]

ALTER TABLE [dbo].[respuesta_usuario] ADD  DEFAULT ((0)) FOR [es_correcta]
ALTER TABLE [dbo].[respuesta_usuario] ADD  DEFAULT ((0)) FOR [tiempo_respuesta_seg]
ALTER TABLE [dbo].[respuesta_usuario] ADD  DEFAULT ((0)) FOR [expiro_tiempo]

ALTER TABLE [dbo].[usuarios] ADD  DEFAULT ((0)) FOR [intentos_practica]
ALTER TABLE [dbo].[usuarios] ADD  DEFAULT ((0)) FOR [intentos_final]
ALTER TABLE [dbo].[usuarios] ADD  DEFAULT ((1)) FOR [activo]

ALTER TABLE [dbo].[examen_preguntas]  WITH CHECK ADD FOREIGN KEY([id_examen])
REFERENCES [dbo].[examenes] ([id_examen])

ALTER TABLE [dbo].[examen_preguntas]  WITH CHECK ADD FOREIGN KEY([id_pregunta])
REFERENCES [dbo].[preguntas] ([id_pregunta])

ALTER TABLE [dbo].[examenes]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[usuarios] ([id_usuario])

ALTER TABLE [dbo].[historial_estudiante]  WITH CHECK ADD FOREIGN KEY([id_examen])
REFERENCES [dbo].[examenes] ([id_examen])

ALTER TABLE [dbo].[historial_estudiante]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[usuarios] ([id_usuario])

ALTER TABLE [dbo].[preguntas]  WITH CHECK ADD FOREIGN KEY([id_imagen])
REFERENCES [dbo].[imagenes] ([id_imagen])

ALTER TABLE [dbo].[respuesta_usuario]  WITH CHECK ADD FOREIGN KEY([id_exam_pregunta])
REFERENCES [dbo].[examen_preguntas] ([id_exam_pregunta])

ALTER TABLE [dbo].[examenes]  WITH CHECK ADD CHECK  (([estado]='Cancelado' OR [estado]='Finalizado' OR [estado]='EnCurso'))
ALTER TABLE [dbo].[examenes]  WITH CHECK ADD CHECK  (([tipo]='Final' OR [tipo]='Practica'))

ALTER TABLE [dbo].[preguntas]  WITH CHECK ADD CHECK  (([nivel]='Avanzado' OR [nivel]='Intermedio' OR [nivel]='Basico'))
ALTER TABLE [dbo].[preguntas]  WITH CHECK ADD CHECK  (([respuesta_correcta]='D' OR [respuesta_correcta]='C' OR [respuesta_correcta]='B' OR [respuesta_correcta]='A'))
ALTER TABLE [dbo].[preguntas]  WITH CHECK ADD CHECK  (([tipo_examen]='Ambos' OR [tipo_examen]='Final' OR [tipo_examen]='Practica'))

ALTER TABLE [dbo].[respuesta_usuario]  WITH CHECK ADD CHECK  (([respuesta_selec]='D' OR [respuesta_selec]='C' OR [respuesta_selec]='B' OR [respuesta_selec]='A'))