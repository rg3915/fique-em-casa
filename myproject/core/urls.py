from django.urls import path
from myproject.core import views as c


app_name = 'core'
urlpatterns = [
    path('', c.home, name='home'),
    path('person/', c.PersonList.as_view(), name='person_list'),
    path('person/add/', c.person_create, name='person_add'),
    path('person/<int:pk>/', c.person_detail, name='person_detail'),
    path('person/<int:pk>/edit/', c.person_update, name='person_edit'),
    path('person/<int:pk>/delete/',
         c.person_delete, name='person_delete'),
    path('expense/', c.ExpenseList.as_view(), name='expense_list'),
    path('expense/print/', c.PrintExpenseList.as_view(), name='print_expenses')
]
