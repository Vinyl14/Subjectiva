import cv2
import pytesseract

# Path to Tesseract executable
pytesseract.pytesseract.tesseract_cmd = r"/opt/homebrew/bin/tesseract"

# Configuration for Tesseract OCR
myconfig = r"--psm 11 --oem 3"

# Initialize resizable parameters for the bounding box
bbox_width = 600
bbox_height = 400

def main():
    global bbox_width, bbox_height
    
    # Accessing the camera
    cap = cv2.VideoCapture(0)

    # Check if the camera is opened successfully
    if not cap.isOpened():
        print("Error: Could not open camera.")
        return
    
    while True:
        # Capture a frame from the camera
        ret, frame = cap.read()

        # Get the dimensions of the frame
        height, width, _ = frame.shape

        # Calculate the bounding box coordinates to place it in the middle
        x = (width - bbox_width) // 2
        y = (height - bbox_height) // 2

        # Define the bounding box
        bbox = (x, y, bbox_width, bbox_height)

        # Draw bounding box on the frame
        x, y, w, h = bbox
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)

        # Display the frame with bounding box
        cv2.imshow('Camera Feed', frame)

        # Check for key press
        key = cv2.waitKey(1) & 0xFF

        # Resize the bounding box if '+' is pressed
        if key == ord('+'):
            bbox_width += 10
            bbox_height += 10

        # Resize the bounding box if '-' is pressed
        elif key == ord('-'):
            bbox_width -= 10
            bbox_height -= 10
            if bbox_width < 10:
                bbox_width = 10
            if bbox_height < 10:
                bbox_height = 10

        # Break loop if 'c' is pressed to capture image
        elif key == ord('c'):
            # Extract the specified area from the frame
            cropped_frame = frame[y:y+h, x:x+w]

            # Convert the cropped frame to grayscale
            gray_frame = cv2.cvtColor(cropped_frame, cv2.COLOR_BGR2GRAY)
            
            # Apply image preprocessing (increase contrast, resize, etc.)
            preprocessed_frame = cv2.resize(gray_frame, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)

            # Perform OCR
            text = pytesseract.image_to_string(preprocessed_frame, config=myconfig)

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
