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
