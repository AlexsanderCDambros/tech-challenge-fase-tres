# Tech Challenge - Fase 3

Repositório do **Tech Challenge** da **Fase 3** da **Pós tech em Frontend Engineering** - **FIAP**.

Acesso ao vídeo de demonstração e entrega do tech challenge: [Link para o vídeo no Youtube](https://youtu.be/5oaMYXk1hVU)

Desenvolvido por Alexsander Chagas Dambros | [LinkedIn](https://www.linkedin.com/in/alexsandercdambros/)

---

## Instruções para baixar e rodar a aplicação

Para poder rodar a aplicação você precisará ter instalado em sua máquina o flutter e o android studio com algum emulador configurado:

- [Link para a documentação do Flutter](https://flutter.dev/?utm_source=google&utm_medium=cpc&utm_campaign=brand_sem&utm_content=latam_br&gclsrc=aw.ds&gad_source=1&gad_campaignid=13034410705&gbraid=0AAAAAC-INI_hKL_m54RpNjR5NSuy5jv13&gclid=Cj0KCQjwrojHBhDdARIsAJdEJ_ezYFHroP2C9gUDwqWEXcj4ADobwM_j9ilAFWyNYv9dacf2pD7Ed30aAmuHEALw_wcB)
- [Link para a documentação do Android Studio](https://developer.android.com/studio?hl=pt-br)

### 1. Clonagem do projeto
    
Para começar faça o download dos arquivos ou clone esse repositório em sua máquina.

Comando para clonar o repositório:
    
`git clone https://github.com/AlexsanderCDambros/tech-challenge-fase-tres.git`

### 2. Configure uma aplicação no Firebase
    
2.1 Acesse o console do firebase 

2.2 Crie um novo projeto no firebase

2.3 Habilite o Storage no firebase, seguindo o passo a passo do console. Depois de criado, adicione a seguinte regra:

```
    rules_version = '2';
    service firebase.storage {
        match /b/{bucket}/o {
            match /{allPaths=**} {
                allow read, write: if true;
            }
        }
    }
```

2.4 Habilite o Firestore Database no firebase, seguindo o passo a passo do console. Depois de criado, adicione a seguinte regra:

```
    rules_version = '2';
    service cloud.firestore {
        match /databases/{database}/documents {
            match /{document=**} {
                allow read, write: if true;
            }
        }
    }
```

2.5 Vá nas configurações do projeto firebase e vincule a aplicação com o projeto firebase, você vai precisar do nome do pacote que pode encontrar no projeto baixado em: `android/app/build.grandle.kts` na propriedade `android.namespace`

2.6 Você terá que baixar o arquivo que o firebase irá gerar e colar ele no projeto baixado em: `android/app` e fazer as demais instruções que terão no passo a passo de configuração do firebase.


### 3. Instalação das dependências 

Depois de ter os arquivos em sua máquina, instale as extensões do dart e do flutter no seu VSCode e as depensências serão baixadas automaticamente.


### 4. Rodar o projeto em desenvolvimento

Quando o processo de instalação das dependências terminar, basta clicar na aba Run and Debug do VSCode e clicar no botão Run e Debug. 
A aplicação deve iniciar no device que você selecionar no canto inferior direito do VSCode.