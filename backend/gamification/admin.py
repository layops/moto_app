# moto_app/backend/gamification/admin.py

from django.contrib import admin
from .models import Score, Group

# Score modelini admin panelinde kaydedin
@admin.register(Score)
class ScoreAdmin(admin.ModelAdmin):
    list_display = ('user', 'group', 'points', 'activity_name', 'completed_at')
    list_filter = ('activity_name', 'completed_at', 'group', 'user')
    search_fields = ('user__username', 'group__name', 'activity_name')
    date_hierarchy = 'completed_at'
    ordering = ('-completed_at',)

# Group modelini admin panelinde kaydedin
@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ('name',)
    search_fields = ('name',)

