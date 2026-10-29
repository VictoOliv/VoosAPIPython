# Consulta de Voos

**Atividade 5 — somente a versão 1.**

Consulta de voos por código ICAO, filtros de chegadas/partidas/todos e tela de detalhes, usando a API Flask.

## Estrutura

- `versao1/`: projeto Flutter completo da versão publicada.
- `backend/`: API Python necessária ao aplicativo.

## Terminal 1 — backend Python

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe app.py
```

Confira http://127.0.0.1:5001/api e deixe o backend rodando.
Em outro terminal, execute o Flutter conforme abaixo.

API principal: `/api/voos?aeroporto=SBGR&tipo=chegadas`, com opções `chegadas`, `partidas` e `todos`.

## Executar o Flutter

Instale o Flutter compatível com `versao1/pubspec.yaml` e execute:

```powershell
cd versao1
flutter pub get
flutter run -d chrome
```

## Verificação básica

```powershell
flutter analyze
flutter build web
```

O projeto foi conferido em Flutter Web em 28/10/2026, com análise e abertura básica.
Esta checagem não é uma bateria completa de testes. Builds nativos não foram validados.

Os testes automatizados existentes podem ser executados com `flutter test` e, no backend, `.venv/Scripts/python.exe -m unittest discover -s tests -v`.
