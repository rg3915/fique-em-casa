# Shell script to create a complete Django project.
# This script require Python 3.x and pyenv
# Settings.py is config to Django 2.2.10

# The project contains:
# Settings config
# Person model and form
# Person list and detail
# Person create, update and delete
# Admin config
# Tests
# Selenium test
# Manage shell

# Download:

# curl https://gist.githubusercontent.com/rg3915/a264d0ade860d2f2b4bf/raw/1e3ca17cc1ed712ceb99f44d848976d41405b896/boilerplate2.sh -o boilerplate2.sh

# wget http://bit.ly/358DLhL -O boilerplate2.sh

# Usage:
# Type the following command, you can change the project name.

# source boilerplate.sh myproject

# Colors
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

PROJECT=${1-myproject}

echo "${green}>>> The name of the project is '$PROJECT'.${reset}"

echo "${green}>>> Remove djangoproject${reset}"
rm -rf djangoproject

echo "${green}>>> Creating djangoproject${reset}"
mkdir djangoproject
cd djangoproject

echo "${green}>>> Creating README.md${reset}"
cat << EOF > README.md
### How to contribute?

* Clone this repository.
* Create virtualenv with Python 3.
* Active the virtualenv.
* Install dependences.
* Run the migrations.

\`\`\`
git clone https://github.com/rg3915/myproject.git
cd myproject
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python contrib/env_gen.py
python manage.py migrate
\`\`\`
EOF


echo "${green}>>> Creating virtualenv${reset}"
python3 -m venv .venv
echo "${green}>>> .venv is created${reset}"

# active
sleep 2
echo "${green}>>> activate the .venv${reset}"
source .venv/bin/activate
PS1="(`basename \"$VIRTUAL_ENV\"`)\e[1;34m:/\W\e[00m$ "
sleep 2

# installdjango
echo "${green}>>> Installing the Django${reset}"
pip install -U pip
pip install django==2.2.10 dj-database-url django-daterange-filter django-localflavor django-widget-tweaks python-decouple pytz selenium django-extensions
pip freeze > requirements.txt

# Create contrib/env-sample
echo "${green}>>> Creating the contrib/env-sample${reset}"
mkdir contrib
cat << EOF > contrib/env-sample
SECRET_KEY=THIS_IS_NOT_A_GOOD_SECRET
DEBUG=True
ALLOWED_HOSTS=127.0.0.1, .localhost, .herokuapp.com
EOF

echo "${green}>>> Copy env-sample to .env${reset}"
cp contrib/env-sample .env

echo "${green}>>> Creating .gitignore${reset}"
cat << EOF > .gitignore
__pycache__/
*.py[cod]
*.sqlite3
*.env
*.DS_Store
.venv/
staticfiles/
.ipynb_checkpoints/
EOF

# createproject
echo "${green}>>> Creating the project '$PROJECT' ...${reset}"
django-admin.py startproject $PROJECT .
cd $PROJECT
echo "${green}>>> Creating the app 'core' ...${reset}"
python ../manage.py startapp core

echo "${green}>>> Creating tests directory${reset}"
mkdir core/tests
touch core/tests/__init__.py
rm -f core/tests.py

echo "${green}>>> Creating data.py${reset}"
cat << EOF > core/tests/data.py
PERSON_DICT = {
    'first_name': 'Regis',
    'last_name': 'da Silva',
    'email': 'regis@example.com',
    'address': 'Rua Major Sampaio, 35',
    'complement': 'apto 303',
    'district': 'Santana',
    'city': 'São Paulo',
    'uf': 'SP',
    'cep': '02035000'}
EOF

echo "${green}>>> Creating test_form_person.py${reset}"
cat << EOF > core/tests/test_form_person.py
from django.test import TestCase
from $PROJECT.core.forms import PersonForm
from .data import PERSON_DICT


class PersonFormTest(TestCase):

    def test_form_has_fields(self):
        ''' Form must have 10 fields '''
        form = PersonForm()
        expected = ['first_name', 'last_name', 'email', 'address',
                    'complement', 'district', 'city', 'uf', 'cep', 'blocked']
        self.assertSequenceEqual(expected, list(form.fields))

    def assertFormErrorMessage(self, form, field, msg):
        errors = form.errors
        errors_list = errors[field]
        self.assertListEqual([msg], errors_list)

    def make_validated_form(self, **kwargs):
        data = dict(**PERSON_DICT, **kwargs)
        form = PersonForm(data)
        form.is_valid()
        return form
EOF

echo "${green}>>> Creating test_model_person.py${reset}"
cat << EOF > core/tests/test_model_person.py
from datetime import datetime
from django.test import TestCase
from django.shortcuts import resolve_url as r
from $PROJECT.core.models import Person
from .data import PERSON_DICT


class PersonModelTest(TestCase):

    def setUp(self):
        self.obj = Person(**PERSON_DICT)
        self.obj.save()

    def test_create(self):
        self.assertTrue(Person.objects.exists())

    def test_created_at(self):
        ''' Person must have an auto created_at attr. '''
        self.assertIsInstance(self.obj.created, datetime)

    def test_str(self):
        self.assertEqual('Regis da Silva', str(self.obj))

    def test_get_absolute_url(self):
        url = r('core:person_detail', self.obj.pk)
        self.assertEqual(url, self.obj.get_absolute_url())
EOF

echo "${green}>>> Creating test_view_person_detail.py${reset}"
cat << EOF > core/tests/test_view_person_detail.py
from django.test import TestCase
from django.shortcuts import resolve_url as r
from $PROJECT.core.models import Person
from .data import PERSON_DICT


class PersonDetailGet(TestCase):

    def setUp(self):
        self.obj = Person.objects.create(**PERSON_DICT)
        self.resp = self.client.get(r('core:person_detail', self.obj.pk))

    def test_get(self):
        self.assertEqual(200, self.resp.status_code)

    def test_template(self):
        self.assertTemplateUsed(
            self.resp, 'core/person_detail.html')

    def test_context(self):
        person = self.resp.context['person']
        self.assertIsInstance(person, Person)

    def test_html(self):
        contents = (self.obj.first_name,
                    self.obj.last_name,
                    self.obj.email,
                    self.obj.address,
                    self.obj.complement,
                    self.obj.district,
                    self.obj.city,
                    self.obj.uf,
                    self.obj.cep)

        with self.subTest():
            for expected in contents:
                self.assertContains(self.resp, expected)


class PersonDetailNotFound(TestCase):

    def test_not_found(self):
        resp = self.client.get(r('core:person_detail', 0))
        self.assertEqual(404, resp.status_code)
EOF

echo "${green}>>> Creating test_view_person_list.py${reset}"
cat << EOF > core/tests/test_view_person_list.py
from django.test import TestCase
from django.shortcuts import resolve_url as r
from $PROJECT.core.models import Person
from .data import PERSON_DICT


class TalkListGet(TestCase):

    def setUp(self):
        self.obj = Person.objects.create(**PERSON_DICT)
        self.resp = self.client.get(r('core:person_list'))

    def test_get(self):
        self.assertEqual(200, self.resp.status_code)

    def test_template(self):
        self.assertTemplateUsed(self.resp, 'core/person_list.html')

    def test_html(self):
        contents = [
            (1, 'Regis da Silva'),
            (1, 'regis@example.com'),
            (1, 'São Paulo'),
        ]

        for count, expected in contents:
            with self.subTest():
                self.assertContains(self.resp, expected, count)


class PersonGetEmpty(TestCase):

    def test_get_empty(self):
        response = self.client.get(r('core:person_list'))

        self.assertContains(response, 'Sem itens na lista.')
EOF

echo "${green}>>> Creating static/css directory${reset}"
mkdir -p core/static/css

echo "${green}>>> Creating main.css${reset}"
cat << EOF > core/static/css/main.css
/* Sticky footer styles
-------------------------------------------------- */
/* http://getbootstrap.com/examples/sticky-footer-navbar/sticky-footer-navbar.css */
/* http://getbootstrap.com/2.3.2/examples/sticky-footer.html */
html {
  position: relative;
  min-height: 100%;
}
body {
  /* Margin bottom by footer height */
  margin-bottom: 60px;
}
#footer {
  position: absolute;
  bottom: 0;
  width: 100%;
  /* Set the fixed height of the footer here */
  height: 60px;
  background-color: #101010;
}
.credit {
  /* Center vertical text */
  margin: 20px 0;
}
/* Lastly, apply responsive CSS fixes as necessary */
@media (max-width: 767px) {
  body {
    margin-bottom: 120px;
  }

  #footer {
    height: 120px;
    padding-left: 5px;
    padding-right: 5px;
  }
}
/* My personal styles. */
.ok {
    color: #44AD41; /*verde*/
}

.no {
    color: #DE2121; /*vermelho*/
}
EOF

echo "${green}>>> Creating social.css${reset}"
cat << EOF > core/static/css/social.css
/* http://www.kodingmadesimple.com/2014/11/create-stylish-bootstrap-3-social-media-icons.html */
.social {
    margin: 0;
    padding: 0;
}

.social ul {
    margin: 0;
    padding: 5px;
}

.social ul li {
    margin: 5px;
    list-style: none outside none;
    display: inline-block;
}

.social i {
    width: 40px;
    height: 40px;
    color: #FFF;
    background-color: #909AA0;
    font-size: 22px;
    text-align:center;
    padding-top: 12px;
    border-radius: 50%;
    -moz-border-radius: 50%;
    -webkit-border-radius: 50%;
    -o-border-radius: 50%;
    transition: all ease 0.3s;
    -moz-transition: all ease 0.3s;
    -webkit-transition: all ease 0.3s;
    -o-transition: all ease 0.3s;
    -ms-transition: all ease 0.3s;
    text-decoration: none;
}

.social .fa-facebook {
    background: #4060A5;
}

.social .fa-twitter {
    background: #00ABE3;
}

.social .fa-google-plus {
    background: #e64522;
}

.social .fa-github {
    background: #343434;
}

.social .fa-pinterest {
    background: #cb2027;
}

.social .fa-linkedin {
    background: #0094BC;
}

.social .fa-flickr {
    background: #FF57AE;
}

.social .fa-instagram {
    background: #375989;
}

.social .fa-vimeo-square {
    background: #83DAEB;
}

.social .fa-stack-overflow {
    background: #FEA501;
}

.social .fa-dropbox {
    background: #017FE5;
}

.social .fa-tumblr {
    background: #3a5876;
}

.social .fa-dribbble {
    background: #F46899;
}

.social .fa-skype {
    background: #00C6FF;
}

.social .fa-stack-exchange {
    background: #4D86C9;
}

.social .fa-youtube {
    background: #FF1F25;
}

.social .fa-xing {
    background: #005C5E;
}

.social .fa-rss {
    background: #e88845;
}

.social .fa-foursquare {
    background: #09B9E0;
}

.social .fa-youtube-play {
    background: #DF192A;
}

.social .fa-slack {
    background: #4F3A4B;
}

.social .fa-whatsapp {
    background: #65BC54;
}

.socialfooter {
    margin: 0;
    padding: 0;
}

.socialfooter ul {
    margin: 0;
    padding: 5px;
}

.socialfooter ul li {
    margin: 5px;
    list-style: none outside none;
    display: inline-block;
}

.socialfooter i {
    color: #FFF;
    font-size: 22px;
    text-align:center;
    padding-top: 12px;
    border-radius: 50%;
    -moz-border-radius: 50%;
    -webkit-border-radius: 50%;
    -o-border-radius: 50%;
    transition: all ease 0.3s;
    -moz-transition: all ease 0.3s;
    -webkit-transition: all ease 0.3s;
    -o-transition: all ease 0.3s;
    -ms-transition: all ease 0.3s;
    text-decoration: none;
}

.socialfooter i:hover {
    color: #00ABE3;
}
EOF

echo "${green}>>> Creating templates directory${reset}"
mkdir -p core/templates/core

echo "${green}>>> Creating base.html${reset}"
cat << EOF > core/templates/base.html
{% load static %}
<!DOCTYPE html>
<html lang="en">
<head>

  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <meta name="description" content="Django boilerplate">
  <meta name="author" content="rg3915">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <link rel="shortcut icon" href="https://www.djangoproject.com/favicon.ico">

  <title>
    {% block title %}Django{% endblock title %}
  </title>

  <!-- Bootstrap core CSS -->
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">
  <link rel="stylesheet" href="{% static "css/main.css" %}">
  <link rel="stylesheet" href="{% static "css/social.css" %}">
  <!-- Bootstrap JS -->
  <script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>

  <style type="text/css">
    body {
      padding-top: 50px;
      /*color: #5a5a5a;*/
    }
  </style>

</head>
<body>
  {% include "nav.html" %}
  <div id="wrap">
    <div class="container">
      {% block content %}{% endblock content %}
    </div>
  </div>
  {% include "footer.html" %}
</body>
</html>
EOF

echo "${green}>>> Creating footer.html${reset}"
cat << EOF > core/templates/footer.html
<div id="footer">
  <div class="container">
    <p class="credit pull-left">Example by <a href="https://github.com/rg3915/">Régis da Silva</a> &copy; 2018 &middot; <a href="">download</a></p>
    <div class="socialfooter pull-center">
      <ul>
        <li><a href="#"><i class="fa fa-facebook"></i></a></li>
        <li><a href="#"><i class="fa fa-twitter"></i></a></li>
        <li><a href="#"><i class="fa fa-google-plus"></i></a></li>
        <li><a href="#"><i class="fa fa-github"></i></a></li>
        <li><a href="#"><i class="fa fa-pinterest"></i></a></li>
        <li><a href="#"><i class="fa fa-linkedin"></i></a></li>
        <li><a href="#"><i class="fa fa-instagram"></i></a></li>
        <li><a href="#"><i class="fa fa-skype"></i></a></li>
        <li><a href="#"><i class="fa fa-slack"></i></a></li>
      </ul>
    </div>
  </div>
</div>
EOF

echo "${green}>>> Creating index.html${reset}"
cat << EOF > core/templates/index.html
{% extends "base.html" %}

{% block content %}
  <div class="jumbotron">
    <h1>Bem vindo!</h1>
    <a href="{% url 'core:person_add' %}">
      <button id="new_customer" type="button" class="btn btn-primary">
        <span class="glyphicon glyphicon-plus"></span> Cadastre-se
      </button>
    </a>
  </div>
{% endblock content %}
EOF

echo "${green}>>> Creating nav.html${reset}"
cat << EOF > core/templates/nav.html
<!-- Menu -->
<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
  <div class="container-fluid">
    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
    </div>
    <div class="navbar-collapse collapse">
      <ul class="nav navbar-nav">
        <li class="current"><a href="{% url 'core:home' %}"><span class="glyphicon glyphicon-home"></span> Home</a></li>
        <li><a href="{% url 'core:person_list' %}"><span class="fa fa-users"></span> Lista de Contatos</a></li>
      </ul>
      <ul class="nav navbar-nav navbar-right">
        <li><a href="{% url 'admin:index' %}"><span class="fa fa-drupal"></span> Admin</a></li>
      </ul>
    </div>
  </div>
</div>
EOF

echo "${green}>>> Creating pagination.html${reset}"
cat << EOF > core/templates/pagination.html
<!-- pagination -->
<div class="row text-center">
  <div class="col-lg-12">
    <ul class="pagination">
      {% if page_obj.has_previous %}
        <li><a href="?page={{ page_obj.previous_page_number }}">&laquo;</a></li>
      {% endif %}
      {% for pg in page_obj.paginator.page_range %}
        {% if page_obj.number == pg %}
          <li class="active"><a href="?page={{ pg }}">{{ pg }}</a></li>
        {% else %}
          <li><a href="?page={{ pg }}">{{ pg }}</a></li>
        {% endif %}
      {% endfor %}
      {% if page_obj.has_next %}
        <li><a href="?page={{ page_obj.next_page_number }}">&raquo;</a></li>
      {% endif %}
    </ul>
  </div>
</div>
<!-- https://www.technovelty.org/web/skipping-pages-with-djangocorepaginator.html -->
EOF

echo "${green}>>> Creating person_detail.html${reset}"
cat << EOF > core/templates/core/person_detail.html
{% extends "base.html" %}

{% load static %}

{% block title %}Person Detail{% endblock title %}

{% block content %}

<ul class="breadcrumb">
  <li><a href="{% url 'core:home' %}">Home</a> <span class="divider"></span></li>
  <li><a href="{% url 'core:person_list' %}">Contatos</a> <span class="divider"></span></li>
  <li class="active">{{ object.full_name }}</li>
</ul>

<div class="col-lg-8">
  <div class="col-md-2 column">
    <img src="https://cdn4.iconfinder.com/data/icons/ionicons/512/icon-person-128.png" class="img-square" style="height: 100px;" />
  </div>
  <div class="col-md-offset-3 column">
    <h1>{{ object.full_name }}</h1>
    {% if object.email %}
      <h4><span class="glyphicon glyphicon-envelope"></span><a href="#"> {{ object.email }}</a></h4>
    {% endif %}
    <div class="social">
      <ul>
        <li><a href="#"><i class="fa fa-facebook"></i></a></li>
        <li><a href="#"><i class="fa fa-twitter"></i></a></li>
        <li><a href="#"><i class="fa fa-google-plus"></i></a></li>
        <li><a href="#"><i class="fa fa-github"></i></a></li>
        <li><a href="#"><i class="fa fa-pinterest"></i></a></li>
        <li><a href="#"><i class="fa fa-linkedin"></i></a></li>
        <li><a href="#"><i class="fa fa-instagram"></i></a></li>
        <li><a href="#"><i class="fa fa-skype"></i></a></li>
        <li><a href="#"><i class="fa fa-slack"></i></a></li>
      </ul>
    </div>
  </div>

  </br>

  <table class="table table-user-information">
    <tbody>
      {% if object.phone_set.all %}
        {% for phone in object.phone_set.all %}
          <tr>
            <th class="col-md-3 text-right"><span class="glyphicon glyphicon-earphone"></span></th>
            <td>{{ phone.phone }} <i class="fa fa-whatsapp ok"></i> {{ phone.get_phone_type_display }}</td>
          </tr>
        {% endfor %}
      {% else %}
        <tr>
          <th class="col-md-3 text-right"><span class="glyphicon glyphicon-earphone"></span></th>
          <td>---</td>
        </tr>
      {% endif %}

      {% if object.address %}
        <tr>
          <th class="col-md-3 text-right"><span class="glyphicon glyphicon-map-marker"></span></th>
          <td>{{ object.address }}
            {% if object.complement %} - {{ object.complement }}{% endif %}
            {% if object.district %} - {{ object.district }}{% endif %}
          </td>
        </tr>
        <tr>
          <th class="col-md-3 text-right"></th>
          <td>
            {% if object.city %}{{ object.city }}{% endif %}
            {% if object.uf %} - {{ object.uf }}{% endif %}
            {% if object.cep %} - {{ object.cep }}{% endif %}
          </td>
        </tr>
      {% endif %}
      <tr>
        <th class="col-md-3 text-right">Bloqueado</th>
          <td><span class="glyphicon {{ object.blocked|yesno:'glyphicon-ok-sign ok,glyphicon-minus-sign no'}}"></span></td>
      </tr>

    </tbody>
  </table>
  <!-- edit -->
  <a href="{% url 'core:person_edit' person.pk %}">
      <button id="edit_person" type="button" class="btn btn-success">
          <span class="fa fa-pencil"></span> Editar
      </button>
  </a>
  <!-- delete with modal -->
  <button type="button" class="btn btn-danger" data-toggle="modal" data-target="#myModal">
      <span class="fa fa-times"></span> Excluir
  </button>
</div>

<!-- Modal -->
<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h4 class="modal-title" id="myModalLabel">Confirmar</h4>
      </div>
        <form action="{% url 'core:person_delete' person.id %}" method="POST">
      <div class="modal-body">
          {% csrf_token %}
          Deseja mesmo deletar "{{ object }}"?
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Fechar</button>
        <input type="submit" class="btn btn-danger" value="Deletar" />
      </div>
        </form>
    </div>
  </div>
</div>


{% endblock content %}
EOF

echo "${green}>>> Creating person_form.html${reset}"
cat << EOF > core/templates/core/person_form.html
{% extends "base.html" %}

{% load widget_tweaks %}

{% block title %}Person Form{% endblock title %}

{% block content %}

<div class="page-header">
    <h2>Novo Contato</h2>
</div>

<form class="form-horizontal" action="." method="POST">
    {% csrf_token %}
    {{ form.non_fields_errors }}
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.first_name.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.first_name|attr:"class:form-control" }} {{ form.first_name.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.last_name.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.last_name|attr:"class:form-control" }} {{ form.last_name.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.email.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.email|attr:"class:form-control" }} {{ form.email.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.address.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.address|attr:"class:form-control" }} {{ form.address.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.complement.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.complement|attr:"class:form-control" }} {{ form.complement.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.district.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.district|attr:"class:form-control" }} {{ form.district.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.city.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.city|attr:"class:form-control" }} {{ form.city.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.uf.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.uf|attr:"class:form-control" }} {{ form.uf.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.cep.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.cep|attr:"class:form-control" }} {{ form.cep.errors }}
        </div>
    </div>
    <div class="form-group">
        <label class="control-label col-sm-2 col-lg-2">
            {{ form.blocked.label }}
        </label>
        <div class="col-sm-4 col-lg-4">
            {{ form.blocked }} {{ form.blocked.errors }}
        </div>
    </div>

    <div class="form-group">
      <div class="col-sm-2 col-sm-offset-2">
        <button type="submit" class="btn btn-primary">Salvar</button>
      </div>
    </div>
</form>

{% endblock content %}
EOF

echo "${green}>>> Creating person_list.html${reset}"
cat << EOF > core/templates/core/person_list.html
{% extends 'base.html' %}

{% block title %}Contatos{% endblock title %}

{% block content %}

<form class="navbar-form navbar-right" action="." method="get">
    <!-- add -->
    <a href="{% url 'core:person_add' %}">
        <button id="new" type="button" class="btn btn-primary">
            <span class="glyphicon glyphicon-plus"></span> Adicionar
        </button>
    </a>
    <!-- search form -->
    <div class="form-group">
      <input id="search_box" name="search_box" type="text" placeholder="Localizar..." class="form-control">
      <button type="submit" class="btn btn-success form-control"><span class="glyphicon glyphicon-search"></span></button>
  </div>
</form>

<div class="page-header">
<h2><h2><i class="fa fa-user"></i> Lista de Contatos</h2>
</div>

<div>
{% if person_list %}
  <table class="table table-striped">
    <thead>
      <tr>
        <th>Nome</th>
        <th>Email</th>
        <th>Telefone</th>
        <th>UF</th>
      </tr>
    </thead>
    <tbody>
    {% for person in person_list %}
      <tr>
        <td><a href="{{ person.get_absolute_url }}">{{ person.full_name }}</a></td>
        <td>{{ person.email }}</td>
        {% if person.phone_set.first %}
          <td>{{ person.phone_set.first }} 
            {% if person.phone_set.count > 1 %}
              <a href="{{ person.get_absolute_url }}">+{{ person.phone_set.count|add:"-1" }}</a>
            {% endif %}
          </td>
        {% else %}
          <td>---</td>
        {% endif %}
        <td>{{ person.get_uf_display }}</td>
      </tr>
    {% endfor %}
    </tbody>
  </table>
{% else %}
  <p class="alert alert-warning">Sem itens na lista.</p>
{% endif %}
</div>

<hr>
<div>
<h4><b>Total:</b> {{ page_obj.paginator.count }} contato{{ page_obj.paginator.count|pluralize }}</h4>
</div>

{% include "pagination.html" %}

{% endblock content %}
EOF

# up one level
cd ..

# ********** EDITING FILES **********
echo "${green}>>> Refactor .env${reset}"
# find SECRET_KEY
grep "SECRET_KEY" $PROJECT/settings.py > .env
# replace =
sed -i "s/ = /=/g" .env
# replace '
sed -i "s/'//g" .env
cat << EOF >> .env
DEBUG=True
ALLOWED_HOSTS=127.0.0.1, .localhost, .herokuapp.com
EOF

echo "${green}>>> Editing settings.py${reset}"
# insert text in line below of string
cat << EOF > $PROJECT/settings.py
"""
Django settings for $PROJECT project.

Generated by 'django-admin startproject' using Django 2.2.5.

For more information on this file, see
https://docs.djangoproject.com/en/2.0/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/2.0/ref/settings/
"""

import os
from decouple import config, Csv
from dj_database_url import parse as dburl

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/1.9/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = config('DEBUG', default=False, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default=[], cast=Csv())

# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # thirty apps
    'widget_tweaks',
    'daterange_filter',
    'django_extensions',
    # my apps
    '$PROJECT.core',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = '$PROJECT.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = '$PROJECT.wsgi.application'


default_dburl = 'sqlite:///' + os.path.join(BASE_DIR, 'db.sqlite3')
DATABASES = {
    'default': config('DATABASE_URL', default=default_dburl, cast=dburl),
}

# Password validation
# https://docs.djangoproject.com/en/2.0/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/2.0/topics/i18n/

LANGUAGE_CODE = 'pt-br'

TIME_ZONE = 'America/Sao_Paulo'

USE_I18N = True

USE_L10N = True

USE_TZ = True

USE_THOUSAND_SEPARATOR = True

DECIMAL_SEPARATOR = ','


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/2.0/howto/static-files/

STATIC_URL = '/static/'

STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

LOGIN_URL = '/admin/login/'

EOF

echo "${green}>>> Creating core/urls.py${reset}"
cat << EOF > $PROJECT/core/urls.py
from django.urls import path
from $PROJECT.core import views as c


app_name = 'core'
urlpatterns = [
    path('', c.home, name='home'),
    path('person/', c.PersonList.as_view(), name='person_list'),
    path('person/add/', c.person_create, name='person_add'),
    path('person/<int:pk>/', c.person_detail, name='person_detail'),
    path('person/<int:pk>/edit/', c.person_update, name='person_edit'),
    path('person/<int:pk>/delete/',
         c.person_delete, name='person_delete'),
]
EOF

echo "${green}>>> Editing urls.py${reset}"
cat << EOF > $PROJECT/urls.py
from django.urls import include, path
from django.contrib import admin

urlpatterns = [
    path('', include('$PROJECT.core.urls', namespace='core')),
    path('admin/', admin.site.urls),
]
EOF

echo "${green}>>> Editing admin.py${reset}"
cat << EOF > $PROJECT/core/admin.py
from daterange_filter.filter import DateRangeFilter
from django.contrib import admin
from .models import Person, Phone
from .forms import PersonForm


class PhoneInline(admin.TabularInline):
    model = Phone
    extra = 1


@admin.register(Person)
class PersonAdmin(admin.ModelAdmin):
    inlines = [PhoneInline]
    list_display = ('__str__', 'email', 'phone', 'uf', 'created', 'blocked')
    date_hierarchy = 'created'
    search_fields = ('first_name', 'last_name', 'email')
    list_filter = (
        # 'uf',
        ('created', DateRangeFilter),
    )
    form = PersonForm

    def phone(self, obj):
        return obj.phone_set.first()

    phone.short_description = 'telefone'
EOF

echo "${green}>>> Creating forms.py${reset}"
cat << EOF > $PROJECT/core/forms.py
from django import forms
from .models import Person


class PersonForm(forms.ModelForm):

    class Meta:
        model = Person
        fields = ['first_name', 'last_name', 'email', 'address',
                  'complement', 'district', 'city', 'uf', 'cep', 'blocked']
EOF

echo "${green}>>> Creating mixins.py${reset}"
cat << EOF > $PROJECT/core/mixins.py
from django.db.models import Q


class NameSearchMixin(object):

    def get_queryset(self):
        queryset = super(NameSearchMixin, self).get_queryset()
        q = self.request.GET.get('search_box')
        if q:
            return queryset.filter(
                Q(first_name__icontains=q) |
                Q(last_name__icontains=q) |
                Q(email__icontains=q))
        return queryset
EOF

echo "${green}>>> Editing models.py${reset}"
cat << EOF > $PROJECT/core/models.py
from django.db import models
from django.shortcuts import resolve_url as r
from localflavor.br.br_states import STATE_CHOICES

PHONE_TYPE = (
    ('pri', 'principal'),
    ('com', 'comercial'),
    ('res', 'residencial'),
    ('cel', 'celular'),
    ('cl', 'Claro'),
    ('oi', 'Oi'),
    ('t', 'Tim'),
    ('v', 'Vivo'),
    ('n', 'Nextel'),
    ('fax', 'fax'),
    ('o', 'outros'),
)


class TimeStampedModel(models.Model):
    created = models.DateTimeField('criado em', auto_now_add=True, auto_now=False)
    modified = models.DateTimeField('modificado em', auto_now_add=False, auto_now=True)

    class Meta:
        abstract = True


class Address(models.Model):
    address = models.CharField(u'endereço', max_length=100, blank=True)
    complement = models.CharField('complemento', max_length=100, blank=True)
    district = models.CharField('bairro', max_length=100, blank=True)
    city = models.CharField('cidade', max_length=100, blank=True)
    uf = models.CharField('UF', max_length=2, choices=STATE_CHOICES, blank=True)
    cep = models.CharField('CEP', max_length=9, blank=True)

    class Meta:
        abstract = True


class Person(TimeStampedModel, Address):
    first_name = models.CharField('nome', max_length=50)
    last_name = models.CharField('sobrenome', max_length=50, null=True, blank=True)
    email = models.EmailField(null=True, blank=True)
    blocked = models.BooleanField('bloqueado', default=False)

    class Meta:
        ordering = ['first_name']
        verbose_name = 'contato'
        verbose_name_plural = 'contatos'

    def __str__(self):
        return ' '.join(filter(None, [self.first_name, self.last_name]))

    full_name = property(__str__)

    def get_absolute_url(self):
        return r('core:person_detail', pk=self.pk)


class Phone(models.Model):
    phone = models.CharField('telefone', max_length=20, blank=True)
    person = models.ForeignKey('Person', on_delete=models.PROTECT)
    phone_type = models.CharField('tipo', max_length=3, choices=PHONE_TYPE, default='pri')

    def __str__(self):
        return self.phone
EOF

echo "${green}>>> Editing views.py${reset}"
cat << EOF > $PROJECT/core/views.py
from django.shortcuts import render
from django.urls import reverse_lazy as r
from django.views.generic import CreateView, ListView, DetailView
from django.views.generic import UpdateView, DeleteView
from .mixins import NameSearchMixin
from .models import Person
from .forms import PersonForm


def home(request):
    return render(request, 'index.html')


class PersonList(NameSearchMixin, ListView):
    model = Person
    paginate_by = 10


person_detail = DetailView.as_view(model=Person)

person_create = CreateView.as_view(model=Person, form_class=PersonForm)

person_update = UpdateView.as_view(model=Person, form_class=PersonForm)

person_delete = DeleteView.as_view(model=Person, success_url=r('core:person_list'))
EOF


echo "${green}>>> Creating shell_person.py${reset}"
mkdir shell
cat << EOF > shell/shell_person.py
import string
import random
import csv
from $PROJECT.core.models import Person, Phone

PHONE_TYPE = ('pri', 'com', 'res', 'cel')
person_list = []

''' Read person.csv '''
with open('fix/person.csv', 'r') as f:
    r = csv.DictReader(f)
    for dct in r:
        person_list.append(dct)
    f.close()

''' Insert Persons '''
obj = [Person(**person) for person in person_list]
Person.objects.bulk_create(obj)


def gen_phone():
    digits_ = str(''.join(random.choice(string.digits) for i in range(11)))
    return '{} 9{}-{}'.format(digits_[:2], digits_[3:7], digits_[7:])

''' Insert Phones '''
persons = Person.objects.all()
for person in persons:
    for i in range(1, random.randint(1, 5)):
        Phone.objects.create(
            person=person,
            phone=gen_phone(),
            phone_type=random.choice(PHONE_TYPE))

# Done
EOF

echo "${green}>>> Creating person.csv${reset}"
mkdir fix
cat << EOF > fix/person.csv
first_name,last_name,email,city,uf,cep
Elliot,Alderson,elliot-alderson@email.com,New York,NY,00000-000
Edward,Alderson,edward-alderson@email.com,New York,NY,00000-000
Angela,Moss,angela-moss@email.com,New York,NY,00000-000
Darlene,Alderson,darlene-alderson@email.com,New York,NY,00000-000
Tyrell,Wellick,tyrell-wellick@email.com,New York,NY,00000-000
Joanna,Wellick,joanna-wellick@email.com,New York,NY,00000-000
Phillip,Price,phillip-price@email.com,New York,NY,00000-000
Whiterose,,whiterose@email.com,New York,NY,00000-000
Ollie,Parker,ollie-parker@email.com,New York,NY,00000-000
Krista,Gordon,krista-gordon@email.com,New York,NY,00000-000
Gideon,Goddard,gideon-goddard@email.com,New York,NY,00000-000
Shayla,Nico,shayla-nico@email.com,New York,NY,00000-000
Terry,Colby,terry-colby@email.com,New York,NY,00000-000
Scott,Knowles,scott-knowles@email.com,New York,NY,00000-000
Fernando,Vera,fernando-vera@email.com,New York,NY,00000-000
Leon,,leon@email.com,New York,NY,00000-000
Romero,,romero@email.com,New York,NY,00000-000
Trenton,,trenton@email.com,New York,NY,00000-000
Mobley,,mobley@email.com,New York,NY,00000-000
Cisco,,cisco@email.com,New York,NY,00000-000
Dominique,DiPierro,dominique-dipierro@email.com,New York,NY,00000-000
Ray,Heyworth,ray-heyworth@email.com,New York,NY,00000-000
Irving,,irving@email.com,New York,NY,00000-000
Sharon,Knowles,sharon-knowles@email.com,New York,NY,00000-000
Susan,Jacobs,susan-jacobs@email.com,New York,NY,00000-000
Sutherland,,sutherland@email.com,New York,NY,00000-000
Hot,Carla,hot-carla@email.com,New York,NY,00000-000
Grant,,grant@email.com,New York,NY,00000-000
Bill,Harper,bill-harper@email.com,New York,NY,00000-000
Rat,Tail,rat-taill@email.com,New York,NY,00000-000
Ron,,ron@email.com,New York,NY,00000-000
Frank,Cody,frank-cody@email.com,New York,NY,00000-000

EOF

echo "${green}>>> Creating selenium_person.py${reset}"
mkdir selenium
cat << EOF > selenium/selenium_person.py
import time
import csv
from random import randint
from selenium import webdriver

page = webdriver.Firefox()
page.maximize_window()
time.sleep(0.5)
page.get('http://localhost:8000/person/add/')

person_list = []

''' Read person.csv '''
with open('fix/person.csv', 'r') as f:
    r = csv.DictReader(f)
    for dct in r:
        person_list.append(dct)
    f.close()

INDEX = randint(0, 9)

fields = [
    ['id_first_name', person_list[INDEX]['first_name']],
    ['id_last_name', person_list[INDEX]['last_name']],
    ['id_email', person_list[INDEX]['email']],
    ['id_city', person_list[INDEX]['city']],
    ['id_uf', person_list[INDEX]['city']],  # deixa city mesmo
    ['id_cep', person_list[INDEX]['cep']],
]

for field in fields:
    search = page.find_element_by_id(field[0])
    search.send_keys(field[1])

# button = page.find_element_by_id('id_submit')
button = page.find_element_by_class_name('btn-primary')
button.click()

page.quit()
EOF

echo "${green}>>> Creating Makefile${reset}"
cat << EOF > Makefile
shell_person:
tabpython manage.py shell_plus < shell/shell_person.py

selenium_person:
tabpython selenium/selenium_person.py

createuser:
tabpython manage.py createsuperuser --username='admin' --email=''

backup:
tabpython manage.py dumpdata core --format=json --indent=2 > fixtures.json

load:
tabpython manage.py loaddata fixtures.json
EOF

sed -i "s/tab/\t/g" Makefile

# migrate
python manage.py makemigrations
python manage.py migrate

echo "${green}>>> Running tests${reset}"
python manage.py test

echo "${green}>>> Populating database...${reset}"
python manage.py shell_plus < shell/shell_person.py

echo "${green}>>> Backup${reset}"
python manage.py dumpdata core --format=json --indent=2 > fixtures.json

echo -n "Create superuser? (y/N) "
read answer
if [ "$answer" == "y" ]; then
    echo "${green}>>> Creating a 'admin' user ...${reset}"
    echo "${green}>>> The password must contain at least 8 characters.${reset}"
    echo "${green}>>> Password suggestions: demodemo${reset}"
    python manage.py createsuperuser --username='admin' --email=''
fi

echo "${green}>>> Running tests again${reset}"
python manage.py test

echo "${green}>>> Installing ipdb and ipython notebook${reset}"
pip install ipdb
pip install ipython\[notebook\]

echo "${green}>>> See the Makefile${reset}"
cat Makefile

echo "${red}>>> Important: Dont add .env in your public repository.${reset}"
echo "${red}>>> KEEP YOUR SECRET_KEY AND PASSWORDS IN SECRET!!!\n${reset}"
echo "${green}>>> Done${reset}"
# https://www.gnu.org/software/sed/manual/sed.html