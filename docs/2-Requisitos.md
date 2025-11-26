# 2 Requisitos


## 2.1 Lista de Atores e Personas

| Persona | Perfil | Caracterização e Dores (Problemas) | Ação Principal na Ferramenta | Expectativas com o Ecobuzz |
| :--- | :--- | :--- | :--- | :--- |
| João Silva | Cidadão Consciente | Morador de apartamento que se frustra com a incerteza da coleta seletiva e o destino do lixo que separa.<br><br>*Dores:*<br>- Desmotivação por não saber se o material é realmente reciclado.<br>- Falta de um meio prático e confiável para o descarte. | Agendar a retirada de seus materiais recicláveis com um catador de forma rápida e confiável. | Ter uma plataforma "tipo Uber" para a reciclagem, garantindo que seu esforço tenha um impacto positivo e direto. |
| Maria Souza | Catadora Autônoma | Trabalhadora que enfrenta grande desgaste físico e imprevisibilidade de renda ao percorrer a cidade em busca de materiais.<br><br>*Dores:*<br>- Renda instável e imprevisível.<br>- Esforço físico excessivo para pouco retorno.<br>- Invisibilidade como prestadora de serviço. | Aceitar e gerenciar coletas agendadas para otimizar sua rota e garantir sua renda diária. | Aumentar e estabilizar sua renda, reduzir o cansaço desnecessário e ser valorizada como uma profissional essencial. |
| Recicla BH | Empresa Compradora | Galpão de triagem que precisa de um fluxo constante de matéria-prima, mas sofre com a inconstância do fornecimento.<br><br>*Dores:*<br>- Fornecimento irregular de material.<br>- Logística de coleta ineficiente e cara.<br>- Falta de um canal direto para negociar com catadores. | Localizar e contatar catadores/cooperativas para negociar a compra de materiais em grande volume. | Usar o app como uma ferramenta B2B para garantir o suprimento de matéria-prima, planejando coletas e reduzindo custos operacionais. (CORRIGIR) |

## 2.2 Lista de Funcionalidades

* Cadastrar usuários (catadores, cidadãos e empresas), permitindo criação de perfis diferenciados conforme o papel na cadeia de reciclagem.
* Montar perfil do catador, possibilitando inserir quais materiais costuma coletar, meios de transporte utilizados, endereço de atuação e uma breve descrição.
* Definir disponibilidade do catador, informando dias e horários em que está apto a realizar coletas.
* Restringir área de atuação do catador, delimitando bairros ou raio de atendimento para receber apenas solicitações compatíveis.
* Filtrar catadores por tipo de material coletado ou por localização (funcionalidade voltada ao cidadão/descartador e à empresa compradora), permitindo localizar de forma mais assertiva o profissional adequado para a coleta.
* Agendar coletas a partir do perfil do catador (funcionalidade voltada ao cidadão/descartador e à empresa compradora), registrando endereço, data, horário e observações.
* Visualizar agenda de coletas, exibindo em uma única tela os compromissos marcados, com endereço, nome do solicitante, descrição e tags que indicam o status da coleta (aguardando aceite, confirmado, coletado, cancelado).
* Aceitar ou recusar coletas agendadas (para catadores), confirmando sua disponibilidade para realizar o serviço.
* Atualizar status da coleta (para catadores), permitindo marcar quando a coleta está confirmada, em andamento ou concluída.
* Avaliar e comentar a experiência após a coleta, permitindo feedback mútuo e construção de reputação.
* Favoritar catadores ou solicitantes frequentes, agilizando novos agendamentos.
* Interagir por chat em tempo real, para alinhar detalhes adicionais da coleta ou negociação de materiais.
* Receber notificações automáticas sobre novos agendamentos, alterações ou confirmações.
* Gerenciar conta e perfil, incluindo edição de dados, redefinição de senha e exclusão de conta.

## 2.3 Requisitos Funcionais

### Matriz de Requisitos Funcionais

| ID | Descrição Resumida | Dificuldade <br> (B/M/A)* | Prioridade <br> (B/M/A)* |
| :--- | :--- | :--- | :--- |
| **RF-01** | Criar tela de cadastro do usuário no aplicativo. | B | A |
| **RF-02** | Criar tela de definição de perfis de usuário (catador, cidadão, empresa). | B | A |
| **RF-03** | Criar funcionalidade da tela de Login. | B | A |
| **RF-04** | Adicionar requisitos para criação de senha. | B | A |
| **RF-05** | Montar o perfil do catador. | B | A |
| **RF-06** | Definir dias e horários de disponibilidade do catador. | B | M |
| **RF-07** | Delimitar a área de atuação do catador no mapa. | M | M |
| **RF-08** | Filtrar os catadores por material e localização. | M | A |
| **RF-09** | Agendar as coletas a partir do perfil de um catador. | M | A |
| **RF-10** | Visualizar a agenda de coletas com status (pendente, aceito, etc.). | B | A |
| **RF-11** | Funcionalidade para o catador aceitar ou recusar coletas. | B | A |
| **RF-12** | Atualização do status da coleta pelo catador (a caminho, concluído). | B | A |
| **RF-13** | Sistema de avaliação mútua e comentários após a coleta. | B | M |
| **RF-14** | Funcionalidade para favoritar catadores ou solicitantes frequentes. | B | B |
| **RF-15** | Chat em tempo real para comunicação entre os usuários. | A | M |
| **RF-16** | Envio de notificações automáticas (novos agendamentos, status, chat). | M | A |
| **RF-17** | Gerenciamento de conta (edição de dados, senha e exclusão). | B | A |
---
*\*B: Baixa, M: Média, A: Alta*


## 2.4 Requisitos Não Funcionais
### Matriz de Requisitos Não Funcionais

| ID | Descrição Resumida | Dificuldade <br> (B/M/A)* | Prioridade <br> (B/M/A)* |
| :--- | :--- | :--- | :--- |
| **RNF-01** | **Usabilidade:** Garantir interface intuitiva para todos os perfis de usuário. | M | A |
| **RNF-02** | **Desempenho:** Otimizar tempo de resposta, consumo de bateria e dados. | M | A |
| **RNF-03** | **Segurança:** Proteger dados dos usuários com criptografia e práticas seguras. | M | A |
| **RNF-04** | **Confiabilidade:** Assegurar entrega de notificações e estabilidade do sistema. | M | A |
| **RNF-05** | **Disponibilidade:** Manter o sistema operacional 24/7 com alto uptime. | M | A |
| **RNF-06** | **Compatibilidade:** Suportar diversas versões de Android/iOS e tamanhos de tela.| M | A |
| **RNF-07** | **Escalabilidade:** Permitir crescimento futuro em número de usuários e regiões. | M | M |
| **RNF-08** | **Manutenibilidade:** Código limpo e documentado para facilitar manutenções futuras.| B | M |
| **RNF-09** | **Acessibilidade:** Seguir diretrizes de acessibilidade para Pessoas com Deficiência.| M | B |
---
*\*B: Baixa, M: Média, A: Alta*


## 2.5 Descrição Resumida dos Casos de Uso ou Histórias de Usuários

Casos de Uso:

Cadastrar perfis de usuário

| UC01 – CADASTRAR PERFIS DE USUÁRIO | 
| -------------------------- |
| **Descrição**: Permitir que novos usuários se cadastrem na plataforma, escolhendo entre os perfis de catador, cidadão ou empresa. |
| **Atores**: Novo usuário |
| **Prioridade**: Alta |
| **Requisitos associados**: RF-01 |
| **Fluxo Principal**: Usuário acessa a tela de cadastro. &rarr; Informa dados pessoais e seleciona o tipo de perfil. &rarr; Sistema valida as informações e cria a conta. &rarr; Usuário recebe confirmação de cadastro. |

Montar perfil do catador 

| UC02 – MONTAR PERFIL DO CATADOR | 
| -------------------------- |
| **Descrição**: Permitir que o catador monte seu perfil com materiais coletados, transporte e área de atuação. |
| **Atores**: Catador |
| **Prioridade**: Alta |
| **Requisitos associados**: RF-02, RF-03, RF-04 |
| **Fluxo Principal**: Catador acessa a tela de cadastro. &rarr; Informa dados pessoais e seleciona o tipo de perfil: catador. &rarr; Informa materiais aceitos, transporte, área de atuação e disponibilidade. &rarr; Sistema valida as informações e cria a conta. &rarr; Usuário recebe confirmação de cadastro. |

Agendar coleta com catador

| UC03 – AGENDAR COLETA COM CATADOR | 
| -------------------------- |
| **Descrição**: Permitir que cidadãos ou empresas agendem coletas diretamente com um catador escolhido. |
| **Atores**: Cidadão, empresa, catador. |
| **Prioridade**: Alta |
| **Requisitos associados**: RF-05, RF-06, RF-07, RF-08 |
| **Fluxo Principal**: Usuário busca catadores por filtro. &rarr; Seleciona um catador e solicita agendamento. &rarr; Catador recebe notificação e aceita ou recusa a coleta. &rarr; Sistema atualiza status na agenda de ambos. |

Atualizar status da coleta

| UC04 – ATUALIZAR STATUS DA COLETA | 
| -------------------------- |
| **Descrição**: Permitir que o catador marque coletas como confirmadas, em andamento ou concluídas. |
| **Atores**: Catador. |
| **Prioridade**: Alta |
| **Requisitos associados**: RF-09 |
| **Fluxo Principal**: Catador abre a agenda. &rarr; Seleciona uma coleta em andamento. &rarr; Atualiza o status conforme o progresso. &rarr; Sistema envia notificação ao solicitante. |

Avaliar e comentar experiência

| UC05 – AVALIAR E COMENTAR EXPERIÊNCIA | 
| -------------------------- |
| **Descrição**: Permitir que os usuários avaliem e comentem a coleta após a conclusão. |
| **Atores**: Cidadão, empresa, catador. |
| **Prioridade**: Média |
| **Requisitos associados**: RF-10 |
| **Fluxo Principal**: Após finalização da coleta, sistema libera campo de avaliação. &rarr; Usuário insere nota/comentário. &rarr; Sistema registra feedback no perfil do outro usuário. |

Interagir por chat

| UC06 – INTERAGIR POR CHAT | 
| -------------------------- |
| **Descrição**: Permitir a troca de mensagens em tempo real entre usuários. |
| **Atores**: Cidadão, empresa, catador. |
| **Prioridade**: Média |
| **Requisitos associados**: RF-12 |
| **Fluxo Principal**: Usuário acessa o perfil de um catador ou uma coleta agendada. &rarr; Seleciona a opção de chat. &rarr; Troca mensagens em tempo real com o outro usuário. |

Receber notificações

| UC07 – RECEBER NOTIFICAÇÕES | 
| -------------------------- |
| **Descrição**: Enviar alertas automáticos sobre agendamentos, confirmações e alterações. |
| **Atores**: Sistema |
| **Prioridade**: Alta |
| **Requisitos associados**: RF-13 |
| **Fluxo Principal**: Sistema identifica novo evento (ex.: coleta marcada). &rarr; Gera notificação para os usuários envolvidos. &rarr; Usuário visualiza e acessa detalhes. |

Gerenciar conta

| UC08 – GERENCIAR CONTA | 
| -------------------------- |
| **Descrição**: Permitir que o usuário edite dados pessoais, redefina senha ou exclua a conta. |
| **Atores**: Usuário |
| **Prioridade**: Alta |
| **Requisitos associados**: RF-14 |
| **Fluxo Principal**: Usuário acessa configurações da conta. &rarr; Edita informações, redefine senha ou solicita exclusão. &rarr; Sistema processa e confirma a alteração. |

História de Usuários:

| EU, <br> COMO... <br> PAPEL |  QUERO/PRECISO... <br> FUNCIONALIDADE | PARA... <br> MOTIVO/VALOR |
| ---- | ---- | ---- |
| Como novo usuário... | quero me cadastrar escolhendo meu perfil, | para ter acesso às ferramentas adequadas ao meu papel na reciclagem. |
| Como catador... | quero montar meu perfil detalhando materiais, transporte e área de atuação, | para que cidadãos e empresas me encontrem com facilidade. |
| Como descartador... | quero filtrar catadores por tipo de material e localização, | para encontrar o profissional mais adequado à minha necessidade. |
| Como descartador... | quero agendar uma coleta com um catador específico, | para garantir o descarte correto de meus recicláveis. |
| Como catador... | quero aceitar ou recusar coletas recebidas, | para organizar minha agenda de forma eficiente. |
| Como usuário... | quero avaliar a experiência após a coleta, | para contribuir com a reputação e qualidade do serviço. |
| Como usuário... | quero usar um chat em tempo real, | para alinhar detalhes da coleta e/ou negociação. |
| Como usuário... | quero receber notificações automáticas, | para não perder compromissos de coleta. |


## 2.6 Restrições Arquiteturais

As restrições impostas ao projeto que afetam sua arquitetura são:

| Categoria                 | Restrição                                                                 |
|----------------------------|---------------------------------------------------------------------------|
| Linguagem e Frameworks     | O aplicativo móvel deverá ser desenvolvido em Flutter/Dart. O backend será implementado utilizando Firebase. |
| Banco de Dados e Persistência | O banco de dados deverá ser NoSQL, utilizando Firebase Firestore para persistência em tempo real. |
| APIs e Integrações         | Toda comunicação será feita via API RESTful. O sistema deverá integrar com Google Maps API para geolocalização e Firebase Cloud Messaging (FCM) para notificações push. |
| Segurança (Básico)         | Comunicação deverá ser feita via HTTPS. Autenticação deverá usar Firebase Authentication com JWT para segurança de tokens. Senhas deverão ser armazenadas de forma criptografada. |
| Versionamento de Código    | Todo o código deverá ser versionado em **Git**, com repositório central (GitHub/GitLab) e fluxo padronizado de branches (desenvolvimento, testes e produção). |

## 2.7 Mecanismos Arquiteturais 

| Análise | Design | Implementação | 
|--- | --- | --- |
| Persistência de dados | Banco de dados NoSQL | Firebase Firestore |
| Autenticação de usuários | Autenticação baseada em tokens | Firebase Authentication |
| Armazenamento de arquivos | Armazenamento de arquivos em nuvem | Firebase Storage |
| Comunicação em tempo real (chat) | WebSocket/Real-time API | Firebase Firestore (via listener em tempo real) |
| Notificações Push | Sistema de envio de notificações push | Firebase Cloud Messaging (FCM) |
| Geolocalização e mapas | API de mapas com geolocalização | Google Maps API + Geolocator |
| Ambiente Front-End | Desenvolvimento mobile com UI fluida | Flutter + Dart |
| Deploy | Deploy contínuo para produção e testes | Flutter build |

