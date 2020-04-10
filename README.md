# fique-em-casa

Projeto de exemplo apresentado na [FiqueEmCasaConf](https://github.com/linuxtips/FiqueEmCasaConf).

Slides em []().

## Este projeto foi feito com:

* Python 3.6
* Django 2.2.12
* jQuery 3.4.1

## Como rodar o projeto?

* Clone esse repositório.
* Crie um virtualenv com Python 3.
* Ative o virtualenv.
* Instale as dependências.
* Rode as migrações.

```
git clone https://github.com/rg3915/fique-em-casa.git
cd fique-em-casa
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python contrib/env_gen.py
python manage.py migrate
```

