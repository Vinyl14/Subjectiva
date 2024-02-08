import cv2
import pytesseract

# Path to Tesseract executable
pytesseract.pytesseract.tesseract_cmd = r"/opt/homebrew/bin/tesseract"

# Configuration for Tesseract OCR
myconfig = r"--psm 11 --oem 3"

def main():
    # Accessing the camera
    cap = cv2.VideoCapture(0)

    # Check if the camera is opened successfully
    if not cap.isOpened():
        print("Error: Could not open camera.")
        return
    
    while True:
        # Capture a frame from the camera
        ret, frame = cap.read()

        # Display the frame
        cv2.imshow('Camera Feed', frame)

        # Check for key press
        key = cv2.waitKey(1) & 0xFF

        # Break loop if 'c' is pressed to capture image
        if key == ord('c'):
            # Convert the frame to grayscale
            gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            
            # Perform OCR
            text = pytesseract.image_to_string(gray_frame, config=myconfig)

            # Save the text to a text file
            with open("output.txt", "w") as text_file:
                text_file.write(text)

            print("Text saved to output.txt")
            break
        # Break loop if 'q' is pressed to quit
        elif key == ord('q'):
            break

    # Release the camera
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
