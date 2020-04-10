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
