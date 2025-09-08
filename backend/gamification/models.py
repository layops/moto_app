from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Group(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name

class Score(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='scores')
    group = models.ForeignKey(Group, on_delete=models.CASCADE, null=True, blank=True, related_name='group_scores')
    points = models.IntegerField(default=0)
    activity_name = models.CharField(max_length=200)
    completed_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.points} pts"

class Achievement(models.Model):
    """Başarım tanımları için model"""
    ACHIEVEMENT_TYPES = [
        ('ride_count', 'Yolculuk Sayısı'),
        ('distance', 'Mesafe'),
        ('speed', 'Hız'),
        ('streak', 'Seri'),
        ('time', 'Zaman'),
        ('special', 'Özel'),
    ]
    
    name = models.CharField(max_length=100, help_text="Başarım adı")
    description = models.TextField(help_text="Başarım açıklaması")
    icon = models.CharField(max_length=50, default='emoji_events', help_text="Material icon adı")
    achievement_type = models.CharField(max_length=20, choices=ACHIEVEMENT_TYPES, help_text="Başarım türü")
    target_value = models.IntegerField(help_text="Hedef değer (örn: 10 yolculuk, 1000 km)")
    points = models.IntegerField(default=0, help_text="Bu başarım için verilecek puan")
    is_active = models.BooleanField(default=True, help_text="Başarım aktif mi?")
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['points', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.points} puan)"

class UserAchievement(models.Model):
    """Kullanıcı başarımları için model"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_achievements')
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE, related_name='user_achievements')
    progress = models.IntegerField(default=0, help_text="Mevcut ilerleme")
    is_unlocked = models.BooleanField(default=False, help_text="Başarım kazanıldı mı?")
    unlocked_at = models.DateTimeField(null=True, blank=True, help_text="Kazanılma tarihi")
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'achievement')
        ordering = ['-unlocked_at', '-created_at']
    
    def __str__(self):
        status = "Kazanıldı" if self.is_unlocked else "Devam ediyor"
        return f"{self.user.username} - {self.achievement.name} ({status})"
    
    def save(self, *args, **kwargs):
        # İlerleme hedef değere ulaştığında başarımı kazan
        if self.progress >= self.achievement.target_value and not self.is_unlocked:
            self.is_unlocked = True
            from django.utils import timezone
            self.unlocked_at = timezone.now()
            
            # Kullanıcıya puan ver
            Score.objects.create(
                user=self.user,
                points=self.achievement.points,
                activity_name=f"Achievement: {self.achievement.name}"
            )
        super().save(*args, **kwargs)
