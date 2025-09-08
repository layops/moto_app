# moto_app/backend/gamification/admin.py

from django.contrib import admin
from .models import Score, Group, Achievement, UserAchievement

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

# Achievement modelini admin panelinde kaydedin
@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    list_display = ('name', 'achievement_type', 'target_value', 'points', 'is_active', 'created_at')
    list_filter = ('achievement_type', 'is_active', 'created_at')
    search_fields = ('name', 'description')
    ordering = ('points', 'name')
    
    fieldsets = (
        ('Genel Bilgiler', {
            'fields': ('name', 'description', 'icon')
        }),
        ('Başarım Ayarları', {
            'fields': ('achievement_type', 'target_value', 'points', 'is_active')
        }),
    )

# UserAchievement modelini admin panelinde kaydedin
@admin.register(UserAchievement)
class UserAchievementAdmin(admin.ModelAdmin):
    list_display = ('user', 'achievement', 'progress', 'target_value', 'is_unlocked', 'unlocked_at')
    list_filter = ('is_unlocked', 'achievement__achievement_type', 'unlocked_at', 'created_at')
    search_fields = ('user__username', 'achievement__name')
    ordering = ('-unlocked_at', '-created_at')
    
    def target_value(self, obj):
        return obj.achievement.target_value
    target_value.short_description = 'Hedef'
    
    readonly_fields = ('unlocked_at',)

