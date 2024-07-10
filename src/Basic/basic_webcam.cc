#include <opencv2/opencv.hpp>

int main() {
    // Open the default camera (typically the first camera)
    cv::VideoCapture cap(0);
    
    // Check if the camera opened successfully
    if (!cap.isOpened()) {
        std::cerr << "Error: Could not open camera" << std::endl;
        return 1;
    }
    
    // Create a window to display the camera feed
    cv::namedWindow("Camera Feed", cv::WINDOW_NORMAL);
    
    // Main loop to capture and display frames from the camera
    while (true) {
        cv::Mat frame;
        // Capture frame-by-frame
        cap >> frame;
        
        // Check if the frame is empty
        if (frame.empty()) {
            std::cerr << "Error: Frame is empty" << std::endl;
            break;
        }
        
        // Display the frame in the window
        cv::imshow("Camera Feed", frame);
        
        // Check for ESC key press to exit the loop
        if (cv::waitKey(1) == 27) // ESC key
            break;
    }
    
    // Release the camera and close all windows
    cap.release();
    cv::destroyAllWindows();
    
    return 0;
}
