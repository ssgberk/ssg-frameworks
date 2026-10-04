# Canonical build.sh and Runner

- **Repo:** `ssgberk/ssg-frameworks`
- **Date:** 2026-10-04
- **Status:** proposed, awaiting review (approved design redistributed from `2026-10-04-modernize-ssgberk-design.md`)
- **Siblings:** `plan.md` (how), `tasks.md` (executable task list) in this directory; roadmap in `benchmark-tool/docs/specs/ROADMAP.md`

## Context

O SSGBerk é um hard fork do [TechEmpower/FrameworkBenchmarks](https://github.com/TechEmpower/FrameworkBenchmarks) que mede o **tempo de build** de static site generators (SSGs): gera N posts markdown de tamanho X, roda o build de cada gerador em um container isolado e mede com `hyperfine`.

Os dois repos estão parados desde setembro de 2019:

| Item | Hoje | Problema |
|---|---|---|
| Geradores | `ubuntu:18.04`, Node 10, hugo 0.58.2, hyperfine 1.7.0 | Imagens EOL; binários só amd64; 8 dockerfiles com linha corrompida (`... \| bash - && /\|RUN curl ...`) |

## Requirements

### Generator contract (design 5.1)

```
<Linguagem>/<nome>/
  benchmark_config.json   # tests[], content[], config[] (formato atual)
  <nome>.dockerfile
  build.sh                # cópia idêntica do build.sh canônico
  README.md
  src/                    # site mínimo
  package.json + package-lock.json | Gemfile + Gemfile.lock | requirements.txt | composer.json + composer.lock
```

### Dockerfiles (design 5.2)

- `FROM ubuntu:24.04`, `ARG DEBIAN_FRONTEND=noninteractive`.
- Arquitetura detectada com `dpkg --print-architecture` (`amd64` | `arm64`) dentro do `RUN`. **Não usar `TARGETARCH`:** o toolset constrói via `docker.APIClient.build` (builder legado), que no Docker 29 funciona mas deixa `TARGETARCH` vazio (verificado em 2026-10-04).
- Pacotes comuns: `build-essential git curl wget jq ca-certificates moreutils tree`.
- hyperfine 1.20.0: `.deb` `hyperfine_1.20.0_${ARCH}.deb`.
- Runtimes:
  - Node 24 LTS via tarball oficial `node-v24.x-linux-${arch}` (`arch` = `x64` | `arm64`); `npm ci`.
  - Ruby do apt (3.2) + `bundler`; `bundle install` com `Gemfile.lock`.
  - Python 3.12 do apt + `python3 -m venv /opt/venv`; `PATH=/opt/venv/bin:$PATH`; `pip install -r requirements.txt`.
  - PHP 8.4 via `ppa:ondrej/php` + Composer.
  - Go/Rust: binário oficial do gerador (`hugo_extended_<v>_linux-${ARCH}.deb`, `zola-v<v>-<arch>-unknown-linux-gnu.tar.gz`).
- Versão de cada gerador em `ARG <NOME>_VERSION` no topo do dockerfile; para npm/gem/pip/composer, a versão exata também fica no manifesto + lockfile.
- `Go/hugo/src/config.toml` tem `disableKinds = ["page", ...]`: o Hugo nunca gerou HTML de posts. Remover `"page"` dessa lista; a verificação de saída (5.4) passa a impedir esse tipo de regressão.

Hugo target version (design 5.3, "Atualizar"):

| Linguagem | Gerador | Versão alvo |
|---|---|---|
| Go | hugo | 0.167.0 |

### Canonical `build.sh` (design 5.4)

Uma única versão, copiada idêntica para cada gerador. Partir da versão do monorepo e aplicar:

- Comparação de `content_size` sem colchetes (seção 4.2).
- Novo `content.type` `3plus`: front matter TOML

  ```
  +++
  title = "<title>"
  date = <YYYY-MM-DD>
  +++
  ```

- Remover os tipos `datajson` e `external`, usados só por Harp e Cuttlebelle.
- Novo campo opcional `config[].output_folder` + `config[].output_glob` no `benchmark_config.json`. Depois do primeiro build, `build.sh` conta os arquivos que batem com o glob; se forem menos que `number_of_files`, imprime `SSGBERK_VERIFY_FAIL expected=<n> got=<m>`. Se o campo não existir, a verificação é pulada (com aviso).
- `hyperfine` **sem** `--ignore-failure`, com `--export-json` e marcadores (seção 4.3), mais `STARTTIME`/`ENDTIME`.
- `delete_post` também limpa o `output_folder` antes de cada rodada (`--prepare`), para que builds incrementais não mascarem o tempo.

O CI do `ssg-frameworks` falha se algum `*/*/build.sh` diferir do canônico (compara todos com `Go/hugo/build.sh`).

## Acceptance criteria

O trabalho está pronto quando:

1. Os 17 geradores da seção 5 passam no smoke test (seção 6.2) localmente em arm64 e no CI em amd64.

### Smoke test per generator (design 6.2)

`./ssgberk --test <nome> -nf 10 -cs 500 -mr 1` deve:

1. construir a imagem (amd64 no CI; arm64 local e no runner `ubuntu-24.04-arm`);
2. gerar 10 posts e construir o site com código de saída 0;
3. passar na verificação de saída (seção 5.4);
4. aparecer em `succeeded.datarate` do `results.json` com `mean > 0`.

### CI (design 6.3, `ssg-frameworks`)

- `ssg-frameworks`: check de `build.sh` idênticos; smoke test em matriz só para os geradores alterados, em `ubuntu-24.04` e `ubuntu-24.04-arm`. O workflow faz checkout do `benchmark-tool` e coloca o repo atual em `frameworks/`.

## Out of scope

- Temas, plugins ou otimizações específicas de algum gerador.
- O monorepo `StaticSiteGeneratorBenchmark`.
- Updating or adding generators other than Hugo (`docs/specs/002-update-existing-generators`, `docs/specs/003-new-generators`).
