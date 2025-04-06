from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.core.mail import send_mail
from django.contrib.auth import get_user_model
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .serializers import UserRegisterSerializer, UserLoginSerializer
from django.contrib.auth.tokens import default_token_generator 
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

@api_view(['POST'])
def user_register(request):
    serializer = UserRegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        profile = user.patientprofile if hasattr(user, 'patientprofile') else user.doctorprofile
     
        refresh = RefreshToken.for_user(user)
        access_token = str(refresh.access_token)
        refresh_token = str(refresh)

        return Response({
            "message": "User registered successfully!",
            "user": {
                "id": user.id,
                "email": user.email,
                "first_name": profile.first_name,
                "last_name": profile.last_name,
                "account_type": request.data['account_type']
            },
            "refresh": refresh_token,
            "access": access_token
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def user_login(request):
    serializer = UserLoginSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.validated_data['user']
        refresh = serializer.validated_data['refresh']
        access = serializer.validated_data['access']

        account_type = serializer.validated_data['account_type']
        first_name = ""
        last_name = ""
        specialization = ""
        if account_type == 'patient':
            first_name = user.patientprofile.first_name
            last_name = user.patientprofile.last_name
        elif account_type == 'doctor':
            first_name = user.doctorprofile.first_name
            last_name = user.doctorprofile.last_name
            specialization = user.doctorprofile.specialization

        response_data = {
            "message": "Login successful!",
            "refresh": refresh, 
            "access": access,    
            "user": {
                "id": user.id,
                "email": user.email,
                "first_name": first_name,
                "last_name": last_name,
                "account_type": account_type
            }
        }
        if account_type == 'doctor':
            response_data['user']['specialization'] = specialization

        return Response(response_data, status=status.HTTP_200_OK, content_type='application/json; charset=utf-8')
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def user_logout(request):
    return Response({"message": "Logout Successful!"}, status=status.HTTP_200_OK)

@api_view(['POST'])
def send_reset_password_email(request):
    email = request.data.get('email')
    
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"error": "No user found with this email"}, status=status.HTTP_404_NOT_FOUND)
    
    token = default_token_generator.make_token(user)
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))
    reset_url = f"diabetesApp://reset-password/{uidb64}/{token}/"

    send_mail(
        subject="Reset Your Password",
        message=f"Click the link below to reset your password:\n{reset_url}",
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[email],
        fail_silently=False,
    )

    return Response({"message": "Password reset link sent successfully!"}, status=status.HTTP_200_OK)

@api_view(['POST'])
def reset_password_confirm(request, uidb64, token):
    new_password = request.data.get('new_password')
    confirm_new_password = request.data.get('confirm_new_password')

    if new_password != confirm_new_password:
        return Response({"error": "Passwords do not match"}, status=status.HTTP_400_BAD_REQUEST)

    if not new_password or not confirm_new_password:
        return Response({"error": "New password and confirmation are required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = User.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, User.DoesNotExist):
        return Response({"error": "Invalid reset link"}, status=status.HTTP_400_BAD_REQUEST)
    
    if not default_token_generator.check_token(user, token):
        return Response({"error": "Invalid or expired token"}, status=status.HTTP_400_BAD_REQUEST)

    user.set_password(new_password)
    user.save()
    
    return Response({"message": "Password reset successfully!"}, status=status.HTTP_200_OK)