# A ideia do Plantão em Dia – por que, para quem e o que já existe

Este documento explica a motivação do projeto, como o app ajuda cada profissional no dia a dia, o que já existe sobre o tema (métodos, estudos e sistemas) e o que diferencia a nossa proposta.

---

## 1. O problema

A **passagem de plantão** é o momento em que a responsabilidade pelo paciente muda de mãos: quem sai precisa contar a quem entra tudo o que aconteceu e tudo o que ainda falta fazer. Na prática, isso costuma acontecer:

- de forma **verbal**, em pé no corredor ou no posto de enfermagem;
- com **anotações em papel** ou no próprio livro de ocorrências;
- **sem roteiro padronizado** – cada profissional passa do seu jeito;
- com **pressa**: dezenas de leitos em poucos minutos, no fim de 12 horas de trabalho.

O resultado é perda de informação: uma dose que ficou para trás, uma saturação que caiu, um exame que não foi colhido, uma alergia que não foi lembrada.

A nossa pesquisa de campo com **23 profissionais da saúde** confirmou isso ([resumo completo](pesquisa/RESUMO_PESQUISA.md)):

| O que encontramos | % |
|---|---:|
| Passam o plantão verbalmente ou em papel | 96% |
| Não seguem um roteiro padronizado no setor | 83% |
| Já presenciaram erro ou atraso por falha na passagem | 83% |
| Discordam que a forma atual seja segura e eficiente | 57% |
| Percebem perda de informação com frequência | 52% |
| Usariam um app para isso | 74% |

## 2. A ideia

Em vez de depender da memória no fim do turno, o **Plantão em Dia** faz o profissional registrar as coisas **na hora em que acontecem**, com poucos toques no celular. Quando o turno acaba, o app **monta sozinho o resumo de cada paciente no formato SBAR** a partir desses registros. Quem assume lê o resumo e toca em **"Li e assumo o plantão"**, o que deixa registrado quem assumiu e a que horas.

Em resumo: **registrar durante → resumo automático no fim → confirmação de quem assume → histórico guardado.**

## 3. Como o app ajuda cada profissional

| Quem | Dificuldade hoje | Como o app ajuda |
|---|---|---|
| **Enfermeiro(a)** | Passa 10–20 leitos de memória em poucos minutos; precisa lembrar doses, sinais alterados e pendências de todos | SBAR gerado automaticamente; tela única de pendências do setor; destaque de pacientes com risco alto e sinais fora da faixa |
| **Técnico(a) / auxiliar de enfermagem** | Controla horários de medicação em papel; dose esquecida só é percebida tarde | Checklist de medicações por horário, com destaque das atrasadas e **notificação no celular** |
| **Médico(a)** | Chega ao plantão sem saber o que mudou nas últimas horas; depende de quem estiver no posto para contar | Abre o detalhe do paciente e vê sinais vitais, intercorrências e medicações do turno, em ordem cronológica, com alertas |
| **Residente** | Recebe muitos pacientes de uma vez e tem medo de deixar algo passar | Resumo padronizado (sempre na mesma ordem: Situação, Histórico, Avaliação, Recomendação) e lista de pendências por paciente |
| **Coordenação / gestão** | Não sabe se a passagem foi feita, nem por quem | Histórico de plantões com responsável, horário de encerramento e confirmação de leitura |
| **Paciente** | Sofre as consequências da informação perdida (dose atrasada, exame não feito, alergia esquecida) | Menos lacunas na troca de turno; alergias sempre visíveis; nada pendente "some" na troca |

Princípios de design que seguimos para isso funcionar num ambiente corrido:

- **poucos toques por registro** e botões grandes (uso com luva, em pé, com pressa);
- **cores de risco** e alertas visuais para o que precisa de atenção primeiro;
- **interface toda em português**, com termos do dia a dia da enfermagem;
- o profissional **não escreve o resumo**: ele sai dos registros, o que economiza tempo no fim do turno.

## 4. O que já existe

### 4.1 Métodos de passagem de plantão

- **SBAR** (*Situation, Background, Assessment, Recommendation*) – surgiu na comunicação da Marinha dos EUA e foi adaptado para a saúde pela Kaiser Permanente no início dos anos 2000. Hoje é recomendado por órgãos de segurança do paciente no mundo todo. **É o formato que o Plantão em Dia usa.**
- **I-PASS** (*Illness severity, Patient summary, Action list, Situation awareness, Synthesis by receiver*) – método criado para residências médicas. Um estudo multicêntrico publicado no *New England Journal of Medicine* (Starmer et al., 2014) em 9 residências pediátricas e mais de 10 mil internações mostrou, após a implantação, **redução de 23% nos erros médicos** (de 24,5 para 18,8 por 100 internações) **e de 30% nos eventos adversos evitáveis** (de 4,7 para 3,3 por 100 internações).
- A ideia de **"síntese por quem recebe"** do I-PASS inspirou a nossa **confirmação de leitura**.

### 4.2 Evidências e normas

- **Joint Commission (EUA)** – a falha de comunicação na passagem de plantão aparece há anos entre as principais causas de eventos sentinela; uma estimativa muito citada, do seu *Center for Transforming Healthcare*, é que cerca de **80% dos erros médicos graves** envolvem falha de comunicação na transferência do paciente. No projeto de passagem de plantão desse centro, com dez hospitais, mais de **37% das passagens eram falhas** (não permitiam que quem recebia cuidasse do paciente com segurança), e os hospitais que adotaram as soluções padronizadas tiveram em média **52% menos passagens falhas**. Em 2017 publicou o *Sentinel Event Alert* nº 58, dedicado só a esse tema.
- **Organização Mundial da Saúde** – em 2007 incluiu a "comunicação durante a passagem de plantão" entre as **soluções prioritárias para a segurança do paciente**.
- **Metas Internacionais de Segurança do Paciente** – a Meta 2 é **"melhorar a comunicação efetiva"** entre profissionais.
- **Brasil** – o **Programa Nacional de Segurança do Paciente** (Portaria MS nº 529/2013) e a **RDC Anvisa nº 36/2013** exigem que os serviços de saúde tenham protocolos de segurança, incluindo comunicação entre equipes.

### 4.3 Sistemas que já fazem algo parecido

| Sistema | Onde | Observação |
|---|---|---|
| **Epic** (ferramentas de *handoff*) | EUA e outros | Módulo de passagem dentro de um prontuário eletrônico completo |
| **Oracle Health** (antigo Cerner) | EUA e outros | Idem, integrado ao prontuário |
| **Tasy** (Philips) | Brasil | Sistema de gestão hospitalar com evolução e passagem de plantão |
| **MV Soul** | Brasil | Sistema de gestão hospitalar com módulos de enfermagem |
| **AGHU** | Hospitais universitários da Ebserh | Sistema público de gestão hospitalar |

## 5. O que diferencia o Plantão em Dia

Os sistemas acima são **prontuários eletrônicos completos**: caros, implantados pela TI do hospital, usados principalmente no computador do posto, e a passagem de plantão é só um módulo entre centenas. Por isso, mesmo em hospitais que têm esses sistemas, a troca de turno continua sendo feita "de boca" ou no papel – exatamente o que a nossa pesquisa mostrou (96%).

| | Prontuários eletrônicos | **Plantão em Dia** |
|---|---|---|
| Foco | Tudo do hospital | **Só a troca de turno** |
| Onde se usa | Computador do posto | **Celular, à beira do leito** |
| Resumo da passagem | Escrito à mão pelo profissional (quando existe) | **Gerado automaticamente** a partir dos registros |
| Confirmação de quem assume | Raramente | **"Li e assumo o plantão"**, com nome e horário |
| Aviso de medicação atrasada | Depende do sistema | **Notificação no celular** |
| Custo e implantação | Alto, projeto de meses | Leve, open source, roda com um servidor simples |
| Como as funções foram escolhidas | Catálogo genérico | **Pesquisa com 23 profissionais** que fazem troca de turno |

O app **não substitui** o prontuário: ele cobre a lacuna da passagem de plantão, que é onde a informação mais se perde.

## 6. Limitações e próximos passos

Por ser um projeto acadêmico, o Plantão em Dia tem limites claros:

- usa **apenas dados fictícios** e uma persistência simples em arquivo JSON – não está pronto para uso com pacientes reais;
- **não está integrado** a nenhum prontuário eletrônico;
- não passou por **validação clínica** nem por adequação formal à **LGPD** (a principal preocupação de 48% dos entrevistados).

Caminhos possíveis para evoluir:

1. banco de dados real, criptografia dos dados em repouso e auditoria de acessos (LGPD);
2. integração com prontuários via **HL7 FHIR**;
3. modo offline com sincronização, para setores com Wi-Fi ruim;
4. teste piloto em um setor, medindo tempo de passagem e pendências esquecidas antes e depois;
5. opção de usar o formato I-PASS além do SBAR.

## Referências

1. STARMER, A. J. et al. Changes in medical errors after implementation of a handoff program. **New England Journal of Medicine**, v. 371, n. 19, p. 1803–1812, 2014.
2. HAIG, K. M.; SUTTON, S.; WHITTINGTON, J. SBAR: a shared mental model for improving communication between clinicians. **The Joint Commission Journal on Quality and Patient Safety**, v. 32, n. 3, p. 167–175, 2006.
3. THE JOINT COMMISSION. **Sentinel Event Alert, Issue 58**: Inadequate hand-off communication. 2017.
4. WORLD HEALTH ORGANIZATION. **Communication during patient hand-overs**. Patient Safety Solutions, v. 1, solução 3, 2007.
5. BRASIL. Ministério da Saúde. **Portaria nº 529, de 1º de abril de 2013**. Institui o Programa Nacional de Segurança do Paciente (PNSP).
6. BRASIL. Agência Nacional de Vigilância Sanitária. **Resolução RDC nº 36, de 25 de julho de 2013**. Institui ações para a segurança do paciente em serviços de saúde.
7. THE JOINT COMMISSION CENTER FOR TRANSFORMING HEALTHCARE. **Hand-off Communications Project** e *Targeted Solutions Tool*. 2010–2012.
8. JOINT COMMISSION INTERNATIONAL. **International Patient Safety Goals** – Meta 2: melhorar a comunicação efetiva.
