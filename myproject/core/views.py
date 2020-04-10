from django.shortcuts import render
from django.urls import reverse_lazy as r
from django.views.generic import CreateView, ListView, DetailView
from django.views.generic import UpdateView, DeleteView
from .mixins import NameSearchMixin
from .models import Person, Expense
from .forms import PersonForm


def home(request):
    return render(request, 'index.html')


class PersonList(NameSearchMixin, ListView):
    model = Person
    paginate_by = 10


person_detail = DetailView.as_view(model=Person)

person_create = CreateView.as_view(model=Person, form_class=PersonForm)

person_update = UpdateView.as_view(model=Person, form_class=PersonForm)

person_delete = DeleteView.as_view(
    model=Person, success_url=r('core:person_list'))


class ExpenseList(ListView):
    model = Expense
    paginate_by = 10


class PrintExpenseList(ListView):
    model = Expense
    template_name = 'core/expense_report.html'

    def get_context_data(self, **kwargs):
        context = super(PrintExpenseList, self).get_context_data(**kwargs)
        expenses = self.get_queryset().values_list('value', flat=True)
        context['total'] = sum(expenses)

        return context
