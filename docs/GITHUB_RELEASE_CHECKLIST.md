# Checklist de Publicación en GitHub

## 1) Higiene previa

- Verificar que no hay claves reales en archivos `.env.*`.
- Confirmar que `OPENROUTER_API_KEY` en plantillas es placeholder.
- Revisar que `.gitignore` cubre logs, reportes y artefactos temporales.

## 2) Calidad funcional

- Ejecutar una corrida mínima con `rag -Target <archivo>`.
- Confirmar `STATUS=NORM_OK` en `outputs/logs/rag_converter_summary.txt`.
- Generar informe comercial y técnico con `rag-report`.

## 3) Documentación

- Revisar `README.md` como portada de producto.
- Verificar `DEV_GUIDE.md` con operación diaria y onboarding.
- Verificar `NOTICE.md` y `CITATION.cff`.

## 4) Legal

- Confirmar `LICENSE` MIT presente.
- Confirmar `NOTICE.md` con solicitud de atribución comercial.

## 5) Estructura recomendada

- Scripts: `Convert-OfficeToRAG.ps1`, `Run-RAG.ps1`, `Enable-RagAlias.ps1`, `Gen-Report.ps1`
- Documentación: `README.md`, `DEV_GUIDE.md`, `docs/GITHUB_RELEASE_CHECKLIST.md`
- Plantillas: `.env.example`

## 6) Release

- Etiquetar versión inicial (ejemplo: `v2.0.0`).
- Publicar notas de release con cambios clave y comandos de arranque rápido.
