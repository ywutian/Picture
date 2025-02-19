# Picture Tools

A powerful Flutter application for image processing, featuring background removal and image composition capabilities.


## Features

### Background Removal
- Batch image selection for background removal
- High-quality background removal using ONNX Runtime and MODNet model
- Automatic result saving
- Support for various image formats (PNG, JPG, JPEG, WebP)

### Image Composition
- Intuitive image editing interface
- Layer-based composition
- Multiple background options (transparent, solid color, gradient, image)
- Export in different formats (PNG, JPG, PDF)


## Getting Started

### Prerequisites
- Flutter SDK (2.10.0 or higher)
- ONNX Runtime
- Android Studio / VS Code
- Minimum SDK version: Android 21, iOS 11.0

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/picture-tools.git
```

2. Navigate to project directory
```bash
cd picture-tools
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

## Technical Stack

- **Frontend**: Flutter, Dart
- **Image Processing**: 
  - ONNX Runtime for model inference
  - MODNet for portrait matting
  - Flutter image processing libraries
- **State Management**: Provider/Bloc
- **Storage**: Local file system with permission handling

## Performance Optimization

- Multithreaded image processing
- Efficient memory management for large images
- Optimized model inference

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [MODNet](https://github.com/ZHKKKe/MODNet) for the background removal model
- ONNX Runtime team
- Flutter community for their amazing support
- All the contributors who helped shape this project

## Contact

If you have any questions or suggestions, please open an issue or contact the maintainers at:
- Email: your.email@example.com
- Twitter: [@yourusername](https://twitter.com/yourusername)
- GitHub Issues: [https://github.com/yourusername/picture-tools/issues](https://github.com/yourusername/picture-tools/issues)

## Roadmap

- [ ] Add batch processing for image composition
- [ ] Implement AI-powered image enhancement
- [ ] Support for video background removal
- [ ] Cloud storage integration
- [ ] Web version deployment
