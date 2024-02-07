import pytesseract
import PIL.Image
import cv2

# Page segmentation modes:

# [c} Orientation and script detection (OSD) only.

# 1 Automatic page segmentation with OSD.

# 2 Automatic page segmentation, but no OSD, or OCR.

# 3 Fully automatic page segmentation, but no OSD. (Default)

# 4 Assume a single column of text of variable sizes.

# 5 Assume a single uniform block of vertically aligned text.

# 6 Assume a single uniform block of text.

# 7 Treat the image as a single text Line.

# 8 Treat the image as a single word.

# 9 Treat the image as a single word in a circle.

# 10 Treat the image as a single character.
# ell Sparse text. Find as much text as possible in no particular order.
# 12 (Sparse text with osD.

# vs Raw Line. Treat the image as a single text Line,

# bypassing hacks that are Tesseract-specific.

# OCR Engine Mode

# 0  Legacy engine only.

#  1 Neural nets LSTM engine only.

# 2 Legacy + LSTM engines.

#  3 Default, based on what is available


myconfig = r"--psm 11 --oem 3"
    
text = pytesseract.image_to_string(PIL.Image.open("./OCR.jpeg"), config=myconfig)
print(text)


# to show how the ocr works by displaying boxes around the characters

# img = cv2.imread("./Test.jpg")

# height, width, _ = img.shape
# boxes = pytesseract.image_to_boxes(img, config=myconfig)

# for box in boxes.splitlines():
#     box = box.split(" ")
#     img = cv2.rectangle(img, (int(box[1]), height - int(box[2])), (int(box[3]), height - int(box[4])), (0, 255, 0), 2)

# cv2.imshow("img", img)
# cv2.waitKey(0)