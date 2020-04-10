from daterange_filter.filter import DateRangeFilter
from django.contrib import admin
from .models import Person, Phone, Expense
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


admin.site.register(Expense)
