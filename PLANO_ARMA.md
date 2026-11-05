# Astra Dodge — Plano: progressão da arma

> Problema: a arma chega ao máximo cedo demais e, depois disso, a campanha não dá mais nada
> para conquistar. Objetivo: **um degrau de arma por setor**, sempre algo a ganhar, sem deixar o
> jogo fácil nem punir demais quem leva dano.
> Data: 05/11/2026 · base: commit `9ad71bf`.

---

## 1. Como é hoje (medido)

| Nível | Tiro | Intervalo | Tiros/s (dano/s) | Cristais para o próximo |
|---|---|---|---|---|
| 1 | 1 reto | 0,333 s | 3 | 4 |
| 2 | 2 retos | 0,333 s | 6 | 6 |
| 3 | 2 retos (**igual ao 2**) | 0,333 s | 6 | 9 |
| 4 | leque de 3 | 0,2 s | **15** (salto de 2,5×) | 12 |
| 5 | leque de 3, centro perfura | 0,18 s | ~17+ | — |

- **31 cristais** levam do 1 ao 5. A poeira solta cristal em 30% das vezes, e drones em 60%.
- Piloto automático no Setor 1: **nível 2 aos 17 s, 3 aos 48 s, 4 aos 94 s, 5 aos 127 s**. O
  setor dura ~190 s + chefe, então a arma fica no máximo ainda no meio do primeiro setor.
- A arma passa para o próximo setor. Se o escudo zera, a nave perde **1 nível inteiro**.
- Resultado: do Setor 2 em diante não há progressão; cristal coletado vira só pontos.

---

## 2. Proposta

### 2.1 Oito degraus, subida suave (+~20% por degrau)
Um degrau por setor, sem saltos. Cada degrau muda algo **visível** (mais um cano, leque, perfuração).

| Degrau | Tiro | Intervalo | Dano/s | vs anterior |
|---|---|---|---|---|
| 1 | 1 reto | 0,30 s | 3,3 | — |
| 2 | 1 reto rápido | 0,24 s | 4,2 | +25% |
| 3 | 2 retos | 0,30 s | 6,7 | +60%* |
| 4 | 2 retos rápidos | 0,26 s | 7,7 | +15% |
| 5 | 2 retos + 1 inclinado de cada lado (fraco: só na brecha) | 0,30 s | 9,0 | +17% |
| 6 | leque de 3 | 0,26 s | 11,5 | +28% |
| 7 | leque de 3, centro perfura | 0,24 s | 12,5+ | +9% (+perfura) |
| 8 | 2 retos + leque de 2, centro perfura | 0,24 s | 16,7 | +33% |

\* O degrau 3 é o primeiro "tiro duplo", o marco da arma (chega no fim do Setor 2).

### 2.2 Teto por setor (o principal)
**O degrau máximo depende do setor: Setor N → teto N+1** (Setor 1: 2; Setor 7 e 8: 8).
- Garante **um degrau novo por setor** (o teto sobe ao entrar no setor seguinte).
- Os chefes podem ser ajustados sabendo a arma que o jogador tem (luta justa e previsível).
- O custo em cristais de cada degrau sobe aos poucos (ex.: 10, 14, 18, 22, 26, 30, 34) para que
  o teto seja alcançado **perto do fim do setor**, não no começo.
- Infinito: teto = 2 + 1 a cada 2 minutos (até 8). Desafio do Dia: igual ao Infinito.

### 2.3 Sobrecarga: cristal nunca é inútil
Com a arma no teto, a barra da arma vira **SOBRECARGA** (dourada). Encheu (8 cristais) →
**6 s de tiro turbinado** (+50% de cadência e tiros perfurantes), com aviso na tela.
É o "algo a ganhar" contínuo, e é curto: ajuda nos apertos sem deixar o jogo fácil.

### 2.4 Dano: perder a barra antes de perder o degrau
Hoje zerar o escudo tira 1 nível inteiro: com a subida mais lenta, isso ficaria cruel.
- Escudo zerou → perde **a barra de cristais** do degrau atual.
- Se a barra já estava vazia → aí sim cai 1 degrau.
- Na luta contra o chefe a regra é a mesma (sem "espiral da morte").

### 2.5 Relação com os módulos (cartas)
Os módulos continuam sendo o "tipo" da arma (ricochete, perfurante, ímã...); o degrau é a
"força". Nenhum módulo muda a cadência, para o teto continuar valendo.

### 2.6 Tela
- HUD: "ARMA 3/4" (degrau / teto do setor) e a barra; no teto, "SOBRECARGA" dourada.
- Ao entrar num setor: "ARMA: novo máximo 4" junto com o título do setor.
- Nave: um cano a mais aparece no desenho a cada degrau (opcional, etapa W4).

---

## 3. Testes automáticos (rodam em todo deploy)

- **Curva**: dano/s sobe a cada degrau, e nenhum salto passa de +60%.
- **Ritmo**: com o piloto, o teto do Setor 1 chega **depois de 60%** do setor (hoje o nível 2 chega aos 17 s e o máximo aos 127 s).
- **Teto**: cristal no teto enche a Sobrecarga, nunca passa do teto; entrar no setor seguinte sobe o teto.
- **Dano**: escudo zerado tira a barra; com barra vazia, cai 1 degrau.
- **Chefes**: com a arma do teto de cada setor, o bot derruba cada chefe numa janela de tempo
  (nem rápido demais, nem arrastado) — reaproveita os testes de campanha que já medem "chefe em X s".
- Checkpoint e save guardam degrau, barra e teto.

---

## 4. Etapas

| Etapa | Entrega |
|---|---|
| **W1** | 8 degraus + custos novos + teto por setor + HUD "ARMA n/teto" + testes de curva e ritmo |
| **W2** | Perder a barra antes do degrau + Sobrecarga |
| **W3** | Ajuste da vida dos chefes com a arma do teto (janela de tempo por chefe) |
| **W4** | Infinito e Desafio do Dia com teto por tempo; desenho da nave mostrando o degrau |
| **W5** | Teste nos dois celulares e ajuste fino dos números |

---

## 5. Decisões (suas)

1. **Teto por setor** (recomendado) ou só custos mais caros, sem teto (o bom jogador sobe mais rápido)?
2. **Sobrecarga** no teto: quer? (recomendado: sim)
3. **Perder a barra antes do degrau** (recomendado) ou manter "perde 1 nível"?
4. **8 degraus** (um por setor, recomendado) ou manter 5 degraus mais lentos?
