# 3 Modelagem e diagramas arquiteturais: (Modelo C4)
O diagrama de arquitetura do *Ecobuzz* é organizado em três camadas principais, cada uma desempenhando um papel fundamental na estrutura do aplicativo. Abaixo, uma explicação simples e direta sobre como essas camadas interagem entre si:

### 1. Camada de Apresentação (Cliente)
- *Usuários* (Cidadãos, Catadores e Empresas) interagem com o sistema através do *Aplicativo Móvel, desenvolvido utilizando o framework **Flutter* e a linguagem *Dart*.
- A *Geolocalização* é implementada por meio do *Google Maps SDK*, permitindo a visualização de catadores e a localização para agendamentos de coletas.
- A camada de apresentação também se conecta ao *Backend como Serviço (BaaS), utilizando o **Firebase SDK* para a comunicação via *HTTPS*.

### 2. Camada de Aplicação (Lógica de Negócios)
- A lógica de negócios é gerenciada pelo *Backend como Serviço* (BaaS), hospedado no *Google Firebase*.
- O backend processa as solicitações feitas pelos usuários e interage diretamente com a camada de persistência, manipulando os dados e executando ações necessárias para o funcionamento do aplicativo.

### 3. Camada de Persistência (Armazenamento e Banco de Dados)
- *Banco de Dados NoSQL: Utiliza o **Firebase Firestore* para armazenar dados dos usuários, catadores, agendamentos de coletas e histórico de transações.
- *Armazenamento de Arquivos: O **Firebase Storage* é utilizado para armazenar e gerenciar arquivos, como imagens e documentos relacionados às coletas e aos catadores.
- *Notificações Push: Utiliza o **Firebase Cloud Messaging (FCM)* para enviar notificações em tempo real para os usuários sobre agendamentos, alterações ou atualizações.

<p align="center"><img width="575" height="664" alt="arquitetura" src="https://github.com/user-attachments/assets/cfb477b6-cb47-405c-8d17-7c5ef89cd025" />
  
<p align="center">
  Figura 1 – Diagrama de Arquitetura  (fonte: https://c4model.com/)
</p>

Essa arquitetura foi projetada para garantir escalabilidade, segurança e eficiência na gestão de dados, utilizando soluções integradas e modernas para facilitar a interação entre os diferentes componentes do sistema e os usuários finais.


## 3.1 Nível 1: Diagrama de Contexto
O Ecobuzz está centralizado em um sistema que interage com três principais grupos de usuários e sistemas externos:

- **Cidadãos**: Interagem com o sistema agendando coletas de materiais recicláveis. Eles buscam conveniência e rastreabilidade no processo de descarte, conectando-se diretamente com os catadores via plataforma.

- **Catadores**: São os profissionais que gerenciam suas coletas, confirmam agendamentos e atualizam o status das coletas. O sistema facilita a visibilidade do seu trabalho e a organização de suas rotas, otimizando a coleta de materiais.

- **Empresas de Reciclagem**: Buscam materiais recicláveis para compra e reutilização. Elas podem localizar e negociar com catadores através do aplicativo, garantindo a continuidade no fornecimento de insumos recicláveis.

Além desses usuários, o sistema se conecta com APIs de geolocalização e plataformas de pagamento, otimizando a localização dos catadores e facilitando transações seguras entre as partes envolvidas.

<img width="3840" height="1162" alt="Mermaid Chart - Create complex, visual diagrams with text  A smarter way of creating diagrams -2025-10-01-222604" src="https://github.com/user-attachments/assets/29d00d56-d98e-4623-95b5-3002ccde9530" />

<p align="center">
  Figura 2 – Diagrama de Contexto  (fonte: https://c4model.com/)
</p>

Esse diagrama reflete a troca de informações e interações essenciais entre os atores do ecossistema do Ecobuzz, sem detalhar aspectos técnicos ou específicos da implementação.

## 3.2 Nível 2: Diagrama de Contêiner

O **Diagrama de Contêiner** apresenta uma visão de alto nível da arquitetura de software do sistema **Ecobuzz** e como as responsabilidades são distribuídas entre os diferentes componentes (contêineres). Este diagrama foca em como os contêineres de software se comunicam entre si e as principais tecnologias utilizadas.

### Arquitetura e Comunicação entre Contêineres

A arquitetura do **Ecobuzz** é composta por diversos contêineres, cada um com responsabilidades específicas, e se comunica de forma eficiente para garantir o funcionamento adequado do sistema. Abaixo estão os principais componentes:

#### 1. **Aplicativo Móvel Ecobuzz**  
- **Tecnologia**: **IOS/Android (Flutter)**  
- **Responsabilidade**: Permite aos **Geradores de Resíduos** agendarem coletas e visualizarem as demandas/rotas dos **Catadores**.  
- **Comunicação**: Acessa funcionalidades da plataforma via **HTTPS/JSON**.  

#### 2. **API Gateway Ecobuzz**  
- **Tecnologia**: **Microserviços/API REST (Spring Boot)**  
- **Responsabilidade**: API central para autenticação, agendamento, localização e chat.  
- **Comunicação**: Acessa funcionalidades da plataforma via **HTTPS/JSON** e recebe notificações push e realiza a comunicação via **TCP/IP**.  

#### 3. **Serviço de Notificações**  
- **Tecnologia**: **Firebase Cloud Messaging (FCM)**  
- **Responsabilidade**: Envia notificações push e facilita a comunicação em tempo real (chat).  
- **Comunicação**: Interage com o **API Gateway Ecobuzz** para enviar notificações.  

#### 4. **Serviço de Geolocalização**  
- **Tecnologia**: **Google Maps API**  
- **Responsabilidade**: Fornece dados de mapa, cálculo de rotas e geolocalização.  
- **Comunicação**: Interage com o **API Gateway Ecobuzz** via **HTTPS/JSON** para fornecer localizações e calcular rotas.  

#### 5. **Banco de Dados**  
- **Tecnologia**: **SQL Database (Firebase Firestore)**  
- **Responsabilidade**: Armazena dados de **Usuários**, **Coletas**, **Materiais** e **Localizações**.  
- **Comunicação**: O **API Gateway Ecobuzz** lê e escreve dados para o banco de dados via **SQL/JDBC**.


<img width="1033" height="1035" alt="diagrama_container" src="https://github.com/user-attachments/assets/af640314-84f2-4ef1-a243-fd04cc769b70" />


<p align="center">
  Figura 3 – Diagrama de Contêiner  (fonte: https://c4model.com/)
</p>

Essa arquitetura foi desenhada para ser simples e eficaz, garantindo a integração e a comunicação eficiente entre as várias partes do sistema. Cada contêiner tem uma função bem definida e é acessado por diferentes tipos de usuários (geradores de resíduos, catadores e empresas de reciclagem), com a comunicação realizada por meio de **APIs RESTful** e **notificações push** para garantir uma experiência fluida e em tempo real.

## 3.3 Nível 3: Diagrama de Componentes

O **Diagrama de Componentes** detalha a composição de cada contêiner no sistema **Ecobuzz**, descrevendo os componentes que o formam, suas responsabilidades e os detalhes tecnológicos/implementação. Esse diagrama oferece uma visão mais granular sobre a arquitetura do sistema, destacando os elementos-chave e as interações entre eles.

### Componentes da Arquitetura

#### 1. **Aplicativo Móvel Ecobuzz**
- **Responsabilidade**: Permite aos **Geradores de Resíduos** agendarem coletas e visualizarem as demandas/rotas dos **Catadores**.
- **Tecnologia**: **IOS/Android (Flutter)**.
- **Comunicação**: O aplicativo se comunica com o **API Gateway Ecobuzz** via **HTTPS/JSON**.

#### 2. **API Gateway Ecobuzz**
- **Responsabilidade**: Serve como a API central que integra todos os módulos e microserviços. Ele autentica os usuários, gerencia agendamentos e rotas, e interage com outros serviços do sistema.
- **Tecnologia**: **Microserviços/API REST (Spring Boot)**.
- **Comunicação**: O **API Gateway** realiza chamadas internas para outros módulos via **Internal API Call** e interage com o banco de dados e outros componentes através de **JDBC**.

#### Componentes Internos do **API Gateway Ecobuzz**:

- **Serviço de Otimização de Rotas**:
  - **Responsabilidade**: Calcula e otimiza as rotas de coleta com base nas demandas e localizações fornecidas.
  - **Tecnologia**: **Internal API Call** para acessar o **Serviço de Geolocalização** e realizar cálculos de rota via **HTTPS/SQL**.

- **Serviço de Agendamento e Demanda**:
  - **Responsabilidade**: Gerencia o ciclo de vida dos pedidos de coleta, como criação, status e cancelamento.
  - **Tecnologia**: **Internal API Call** com integração com o **Banco de Dados** para persistência de dados via **JDBC/ORM**.

- **Serviço de Autenticação e Usuário**:
  - **Responsabilidade**: Gerencia a identidade e o acesso dos **Catadores**, **Geradores** e **Empresas**.
  - **Tecnologia**: **Internal API Call** com autenticação via **OAuth2/JSON**.

- **Serviço de Transação e Histórico**:
  - **Responsabilidade**: Registra volumes, transações financeiras e gera estatísticas.
  - **Tecnologia**: **Internal API Call** e comunicação com o **Banco de Dados** para persistir dados financeiros via **JDBC**.

- **Serviço de Comunicação**:
  - **Responsabilidade**: Gerencia o chat entre **Geradores de Resíduos** e **Catadores** e envia notificações push/alertas.
  - **Tecnologia**: **Internal API Call**, integração com o **Serviço de Notificações** via **HTTPS/JSON**.

### 3. **Serviço de Notificações**
- **Responsabilidade**: Envia notificações push para os usuários sobre agendamentos, coletas e atualizações.
- **Tecnologia**: **Firebase Cloud Messaging (FCM)**.
- **Comunicação**: O serviço interage com o **API Gateway Ecobuzz** para receber as solicitações de envio de notificações e mensagens.

### 4. **Serviço de Geolocalização**
- **Responsabilidade**: Fornece dados de mapa, cálculo de rotas e geolocalização.
- **Tecnologia**: **Google Maps API**.
- **Comunicação**: Interage com o **API Gateway Ecobuzz** via **HTTPS/SQL** para fornecer localizações e otimizar rotas.

### 5. **Banco de Dados**
- **Responsabilidade**: Armazena dados de **Usuários**, **Coletas**, **Materiais**, **Localizações** e **Histórico de Transações**.
- **Tecnologia**: **SQL Database (Firebase Firestore)**.
- **Comunicação**: O **API Gateway Ecobuzz** lê e escreve dados para o banco de dados via **JDBC/ORM**.


### Estilos e Padrões Arquiteturais Utilizados

A arquitetura segue o estilo de **microserviços**, com cada componente sendo independente, escalável e facilmente reutilizável. Os principais padrões adotados incluem:

- **API Gateway**: Para consolidar todas as interações entre os módulos e fornecer uma interface unificada.
- **Internal API Calls**: Para a comunicação eficiente entre os módulos do sistema.
- **JDBC/ORM**: Para a persistência de dados no banco de dados SQL.

### Componentes Reutilizáveis, Proprietários e a Desenvolver

- **Reutilizáveis**:  
  - **Serviço de Geolocalização** (Google Maps API).
  - **Serviço de Notificações** (Firebase Cloud Messaging).
  
- **Proprietários**:  
  - **API Gateway Ecobuzz** (desenvolvido internamente).

- **A Desenvolver**:  
  - **Serviço de Otimização de Rotas** (cálculo e otimização de rotas baseadas em dados do sistema).
  - **Serviço de Comunicação** (chat em tempo real entre usuários e catadores).



<img width="1090" height="1100" alt="diagrama_componente" src="https://github.com/user-attachments/assets/6094e5df-5c49-402f-830b-3385d3c2ae21" />

<p align="center">
  Figura 4 – Diagrama de Componentes  (fonte: https://c4model.com/)
</p>

Este nível de modelagem ajuda a visualizar a distribuição das responsabilidades e como os componentes interagem entre si, facilitando tanto a implementação quanto o suporte operacional.


## 3.4 Nível 4: Código

Neste nível, apresentamos a implementação dos componentes do sistema *Ecobuzz* e como os elementos são estruturados no código, incluindo a arquitetura de banco de dados e as relações entre as entidades. Abaixo, mostramos o *diagrama de Entidade/Relacionamento (ER)*, que detalha as tabelas do banco de dados e suas interações, além das estruturas necessárias para suportar o funcionamento da aplicação.

### Diagrama de Entidade/Relacionamento (ER)

O diagrama a seguir descreve a arquitetura de dados do sistema *Ecobuzz*:

- **USUÁRIO**: Contém informações sobre os usuários do sistema, como nome, e-mail, senha e tipo de usuário (cidadão, catador ou empresa).
- **CATADOR**: Relacionado a um **USUÁRIO**, descreve as informações do catador, como materiais que aceita, transporte, localização e disponibilidade.
- **EMPRESA_COMPRADORA**: Relacionada a um **USUÁRIO**, descreve as empresas compradoras de material reciclável, incluindo tipo de material comprado e valor pago por material.
- *AGENDAMENTO: Relaciona o **USUÁRIO** com o *CATADOR*, registrando a data, hora e status da coleta.
- *MATERIAL*: Define os materiais recicláveis, como papel, plástico, vidro, que podem ser coletados pelos catadores.
- *NOTIFICAÇÃO*: Relaciona o **USUÁRIO** com um *AGENDAMENTO*, enviando notificações sobre o status da coleta.
- *CHAT: Facilita a comunicação entre o **USUÁRIO** e o *CATADOR*, permitindo o envio de mensagens.
- *MENSAGEM: Registra as mensagens trocadas no **CHAT** entre **USUÁRIOS** e **CATADORES**.

### Estrutura do Banco de Dados

A arquitetura do banco de dados segue um modelo *NoSQL* utilizando o *Firebase Firestore*. As coleções de dados são organizadas para refletir as entidades descritas no diagrama ER:

- **Usuarios**: Armazena informações de todos os usuários, incluindo catadores, cidadãos e empresas.
- **Catadores**: Cada catador possui um documento que descreve sua atuação, materiais aceitos, transporte e disponibilidade.
- **Empresas Compradoras**: Contém detalhes sobre as empresas que compram materiais recicláveis.
- **Agendamentos**: Registra os detalhes dos agendamentos de coleta, associando um catador e um usuário a cada coleta.
- **Materiais**: Guarda informações sobre os tipos de materiais recicláveis.
- **Notificações**: Armazena as notificações relacionadas aos agendamentos, como atualizações sobre status.
- **Chats**: Armazena os chats entre os usuários e os catadores.
- **Mensagens**: Registra as mensagens trocadas dentro de cada chat.


<img width="2769" height="3840" alt="Mermaid Chart - Create complex, visual diagrams with text  A smarter way of creating diagrams -2025-10-01-220745" src="https://github.com/user-attachments/assets/c9491285-5709-4d4e-93e1-2a9bb4f0bbe9" />

<p align="center">
    Figura 5 – Diagrama de Entidade Relacionamento (ER) 
</p>

### Exemplo de Estrutura de JSON

O *JSON* de exemplo para o *AGENDAMENTO* poderia ter a seguinte estrutura:

```json
{
  "id_agendamento": "001",
  "id_usuario": "user123",
  "id_catador": "catador456",
  "data": "2025-10-10",
  "hora": "14:30",
  "status": "confirmado",
  "observacoes": "Material reciclável: papelão"
}
