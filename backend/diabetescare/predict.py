import pickle
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler

# Load the trained model and scaler
try:
    with open("/kaggle/input/uhvuiyyviyv/transformers/default/1/diabetes.pkl", "rb") as file:
        model = pickle.load(file)
    with open("/kaggle/input/uyvvyiviyv/scikitlearn/default/1/scaler.pkl", "rb") as file:
        scaler = pickle.load(file)
except FileNotFoundError:
    print("Error: Model or scaler file not found. Please ensure 'diabetes.pkl' and 'scaler.pkl' are in the current directory.")
    exit(1)

# Define the feature columns (same as in training)
numerical_cols = ['Pregnancies', 'Glucose', 'BloodPressure', 'SkinThickness', 'Insulin', 
                  'BMI', 'DiabetesPedigreeFunction', 'Age']
categorical_cols = ['NewBMI_Obesity 1', 'NewBMI_Obesity 2', 'NewBMI_Obesity 3', 
                   'NewBMI_Overweight', 'NewBMI_Underweight', 'NewInsulinScore_Normal', 
                   'NewGlucose_Low', 'NewGlucose_Normal', 'NewGlucose_Overweight', 'NewGlucose_Secret']

# Function to get user input
def get_user_input():
    print("Please enter the following information:")
    data = {}
    
    for col in numerical_cols:
        while True:
            try:
                value = float(input(f"Enter {col}: "))
                data[col] = value
                break
            except ValueError:
                print("Invalid input. Please enter a number.")
    
    return data

# Function to preprocess the input data
def preprocess_input(data):
    df = pd.DataFrame([data])
    
    # Create categorical features
    bmi = df['BMI'].iloc[0]
    df['NewBMI_Obesity 1'] = 1 if 29.9 < bmi <= 34.9 else 0
    df['NewBMI_Obesity 2'] = 1 if 34.9 < bmi <= 39.9 else 0
    df['NewBMI_Obesity 3'] = 1 if bmi > 39.9 else 0
    df['NewBMI_Overweight'] = 1 if 24.9 < bmi <= 29.9 else 0
    df['NewBMI_Underweight'] = 1 if bmi < 18.5 else 0
    
    insulin = df['Insulin'].iloc[0]
    df['NewInsulinScore_Normal'] = 1 if 16 <= insulin <= 166 else 0
    
    glucose = df['Glucose'].iloc[0]
    df['NewGlucose_Low'] = 1 if glucose <= 70 else 0
    df['NewGlucose_Normal'] = 1 if 70 < glucose <= 99 else 0
    df['NewGlucose_Overweight'] = 1 if 99 < glucose <= 126 else 0
    df['NewGlucose_Secret'] = 1 if glucose > 126 else 0
    
    # Ensure all expected columns are present
    for col in categorical_cols:
        if col not in df.columns:
            df[col] = 0
    
    # Reorder columns to match training data
    df = df[numerical_cols + categorical_cols]
    
    return df

# Function to scale numerical features
def scale_features(df, scaler):
    # Scale numerical features
    numerical_data = df[numerical_cols]
    scaled_data = scaler.transform(numerical_data)
    # Combine scaled numerical features with categorical features
    scaled_df = np.hstack([scaled_data, df[categorical_cols].values])
    return scaled_df

# Main function to predict
def predict_diabetes():
    user_data = get_user_input()
    processed_data = preprocess_input(user_data)
    scaled_data = scale_features(processed_data, scaler)
    
    # Make prediction
    prediction = model.predict(scaled_data)
    probability = model.predict_proba(scaled_data)[0]
    
    # Output result
    result = "Positive" if prediction[0] == 1 else "Negative"
    print(f"\nPrediction: {result}")
    print(f"Probability of Negative: {probability[0]:.2f}")
    print(f"Probability of Positive: {probability[1]:.2f}")

# Run the prediction
if __name__ == "__main__":
    predict_diabetes()