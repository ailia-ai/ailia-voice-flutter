// Generate voice from text

import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart'; // malloc
import 'package:ailia_voice/ailia_voice.dart' as ailia_voice_dart;

String _ailiaCommonGetPath() {
  if (Platform.isAndroid || Platform.isLinux) {
    return 'libailia.so';
  }
  if (Platform.isMacOS) {
    return 'libailia.dylib';
  }
  if (Platform.isWindows) {
    return 'ailia.dll';
  }
  return 'internal';
}

String _ailiaCommonGetAudioPath() {
  if (Platform.isAndroid || Platform.isLinux) {
    return 'libailia_audio.so';
  }
  if (Platform.isMacOS) {
    return 'libailia_audio.dylib';
  }
  if (Platform.isWindows) {
    return 'ailia_audio.dll';
  }
  return 'internal';
}

String _ailiaCommonGetVoicePath() {
  if (Platform.isAndroid || Platform.isLinux) {
    return 'libailia_voice.so';
  }
  if (Platform.isMacOS) {
    return 'libailia_voice.dylib';
  }
  if (Platform.isWindows) {
    return 'ailia_voice.dll';
  }
  return 'internal';
}

ffi.DynamicLibrary _ailiaCommonGetLibrary(String path) {
  final ffi.DynamicLibrary library;
  if (Platform.isIOS) {
    library = ffi.DynamicLibrary.process();
  } else {
    library = ffi.DynamicLibrary.open(path);
  }
  return library;
}

/// Holds the result of speech synthesis.
///
/// Contains PCM audio data, sample rate, and channel count.
class AiliaVoiceResult {
  /// The sample rate in Hz.
  final int sampleRate;

  /// The number of audio channels.
  final int nChannels;

  /// The PCM audio data as a list of float values.
  final List<double> pcm;

  /// Creates an [AiliaVoiceResult].
  AiliaVoiceResult({
    required this.sampleRate,
    required this.nChannels,
    required this.pcm,
  });
}

/// A wrapper class for ailia Voice.
///
/// Provides text-to-speech functionality using the ailia Voice native library.
/// Supports Tacotron2, GPT-SoVITS V1/V2/V3/V2Pro models.
class AiliaVoiceModel {
  /// The handle to the ailia library.
  ffi.DynamicLibrary? ailia;

  /// The handle to the ailia Audio library.
  ffi.DynamicLibrary? ailiaAudio;

  /// The ailia Voice FFI instance.
  dynamic ailiaVoice;

  /// The native pointer to the ailia Voice instance.
  ffi.Pointer<ffi.Pointer<ailia_voice_dart.AILIAVoice>>? ppAilia;

  /// Whether the model is available for inference.
  bool available = false;

  /// Whether to enable debug output.
  bool debug = false;

  /// Checks the error code and throws an exception if it indicates failure.
  ///
  /// [funcName] is the function name to include in the error message.
  /// [code] is the return value from the native API.
  void throwError(String funcName, int code) {
    if (code != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      ffi.Pointer<Utf8> p =
          ailiaVoice.ailiaVoiceGetErrorDetail(ppAilia!.value).cast<Utf8>();
      String errorDetail = p.toDartString();
      throw Exception("$funcName failed $code \n detail $errorDetail");
    }
  }

  /// Retrieves the native API callback structure.
  ///
  /// Obtains function pointers from the ailia, ailia Audio, and ailia Voice
  /// dynamic libraries and populates an [AILIAVoiceApiCallback] structure.
  ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> getCallback() {
    ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> callback =
        malloc<ailia_voice_dart.AILIAVoiceApiCallback>();

    callback.ref.ailiaAudioResample = ailiaAudio!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
            )>>('ailiaAudioResample');
    callback.ref.ailiaAudioGetResampleLen = ailiaAudio!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
            )>>('ailiaAudioGetResampleLen');
    callback.ref.ailiaAudioGetFrameLen = ailiaAudio!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
            )>>('ailiaAudioGetFrameLen');
    callback.ref.ailiaAudioGetSpectrogram = ailiaAudio!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Float,
              ffi.Int,
            )>>('ailiaAudioGetSpectrogram');
    callback.ref.ailiaAudioGetMelSpectrogram = ailiaAudio!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Float,
              ffi.Int,
              ffi.Float,
              ffi.Float,
              ffi.Int,
              ffi.Int,
              ffi.Int,
            )>>('ailiaAudioGetMelSpectrogram');
    callback.ref.ailiaCreate = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Pointer<ailia_voice_dart.AILIANetwork>>,
              ffi.Int,
              ffi.Int,
            )>>('ailiaCreate');
    callback.ref.ailiaOpenWeightFileA = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Char>,
            )>>('ailiaOpenWeightFileA');
    callback.ref.ailiaOpenWeightFileW = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.WChar>,
            )>>('ailiaOpenWeightFileW');
    callback.ref.ailiaOpenWeightMem = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.UnsignedInt,
            )>>('ailiaOpenWeightMem');
    callback.ref.ailiaSetMemoryMode = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.UnsignedInt,
            )>>('ailiaSetMemoryMode');
    callback.ref.ailiaDestroy = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Void Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaDestroy');
    callback.ref.ailiaUpdate = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaUpdate');

    callback.ref.ailiaGetBlobIndexByInputIndex = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.UnsignedInt>,
              ffi.UnsignedInt,
            )>>('ailiaGetBlobIndexByInputIndex');

    callback.ref.ailiaGetBlobIndexByOutputIndex = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.UnsignedInt>,
              ffi.UnsignedInt,
            )>>('ailiaGetBlobIndexByOutputIndex');
    callback.ref.ailiaGetBlobData = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.UnsignedInt,
              ffi.UnsignedInt,
            )>>('ailiaGetBlobData');

    callback.ref.ailiaSetInputBlobData = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.UnsignedInt,
              ffi.UnsignedInt,
            )>>('ailiaSetInputBlobData');

    callback.ref.ailiaSetInputBlobShape = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ailia_voice_dart.AILIAShape>,
              ffi.UnsignedInt,
              ffi.UnsignedInt,
            )>>('ailiaSetInputBlobShape');

    callback.ref.ailiaGetBlobShape = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ailia_voice_dart.AILIAShape>,
              ffi.UnsignedInt,
              ffi.UnsignedInt,
            )>>('ailiaGetBlobShape');

    callback.ref.ailiaGetInputBlobCount = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.UnsignedInt>t,
            )>>('ailiaGetInputBlobCount');
    callback.ref.ailiaGetOutputBlobCount = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.UnsignedInt>,
            )>>('ailiaGetOutputBlobCount');

    callback.ref.ailiaGetErrorDetail = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Pointer<ffi.Char> Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaGetErrorDetail');

    callback.ref.ailiaCopyBlobData = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.UnsignedInt,
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.UnsignedInt,
            )>>('ailiaCopyBlobData');

    return callback;
  }

  void _create(int envId) {
    close();

    ailiaVoice = ailia_voice_dart.ailiaVoiceFFI(
      _ailiaCommonGetLibrary(_ailiaCommonGetVoicePath()),
    );
    ailia = _ailiaCommonGetLibrary(_ailiaCommonGetPath());
    ailiaAudio = _ailiaCommonGetLibrary(_ailiaCommonGetAudioPath());

    ppAilia = malloc<ffi.Pointer<ailia_voice_dart.AILIAVoice>>();

    ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> callback =
        getCallback();

    int memoryMode = ailia_voice_dart.AILIA_MEMORY_REDUCE_CONSTANT |
        ailia_voice_dart.AILIA_MEMORY_REDUCE_CONSTANT_WITH_INPUT_INITIALIZER |
        ailia_voice_dart.AILIA_MEMORY_REUSE_INTERSTAGE;
    int flag = ailia_voice_dart.AILIA_VOICE_FLAG_NONE;

    int status = ailiaVoice.ailiaVoiceCreate(
      ppAilia,
      envId,
      ailia_voice_dart.AILIA_MULTITHREAD_AUTO,
      memoryMode,
      flag,
      callback.ref,
      ailia_voice_dart.AILIA_VOICE_API_CALLBACK_VERSION,
    );
    throwError("ailiaVoiceCreate", status);

    malloc.free(callback);
  }

  void _finalizeOpen() {
    if (debug){
      print("ailia Voice initialize success");
    }
    available = true;
  }

  /// Opens a Tacotron2 model.
  ///
  /// [encoder] is the path to the encoder model file.
  /// [decoder1] is the path to the decoder model file.
  /// [decoder2] is the path to the postnet model file.
  /// [wave] is the path to the waveform generation model file.
  /// [ssl] is the path to the SSL model file (null for Tacotron2).
  /// [modelType] is the model type constant.
  /// [cleanerType] is the cleaner type constant.
  /// [envId] is the execution environment ID.
  void openModel(
    String encoder,
    String decoder1,
    String decoder2,
    String wave,
    String? ssl,
    int modelType,
    int cleanerType,
    int envId,
  ) {
    _create(envId);

    int status;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceOpenModelFileW(
        ppAilia!.value,
        encoder.toNativeUtf16().cast<ffi.WChar>(),
        decoder1.toNativeUtf16().cast<ffi.WChar>(),
        decoder2.toNativeUtf16().cast<ffi.WChar>(),
        wave.toNativeUtf16().cast<ffi.WChar>(),
        (ssl != null) ? ssl.toNativeUtf16().cast<ffi.WChar>():ffi.nullptr,
        modelType,
        cleanerType,
      );
    }else{
      status = ailiaVoice.ailiaVoiceOpenModelFileA(
        ppAilia!.value,
        encoder.toNativeUtf8().cast<ffi.Char>(),
        decoder1.toNativeUtf8().cast<ffi.Char>(),
        decoder2.toNativeUtf8().cast<ffi.Char>(),
        wave.toNativeUtf8().cast<ffi.Char>(),
        (ssl != null) ? ssl.toNativeUtf8().cast<ffi.Char>():ffi.nullptr,
        modelType,
        ailia_voice_dart.AILIA_VOICE_CLEANER_TYPE_BASIC,
      );
    }
    throwError("ailiaVoiceOpenModelFile", status);

    _finalizeOpen();
  }

  /// Opens a GPT-SoVITS V1 model.
  ///
  /// [encoder] is the path to the t2s_encoder model file.
  /// [decoder1] is the path to the t2s_fsdec model file.
  /// [decoder2] is the path to the t2s_sdec model file.
  /// [wave] is the path to the VITS model file.
  /// [ssl] is the path to the CNHuBERT SSL model file.
  /// [envId] is the execution environment ID.
  void openGPTSoVITSV1Model(
    String encoder,
    String decoder1,
    String decoder2,
    String wave,
    String ssl,
    int envId,
  ) {
    _create(envId);

    int status;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceOpenGPTSoVITSV1ModelFileW(
        ppAilia!.value,
        encoder.toNativeUtf16().cast<ffi.WChar>(),
        decoder1.toNativeUtf16().cast<ffi.WChar>(),
        decoder2.toNativeUtf16().cast<ffi.WChar>(),
        wave.toNativeUtf16().cast<ffi.WChar>(),
        ssl.toNativeUtf16().cast<ffi.WChar>(),
      );
    }else{
      status = ailiaVoice.ailiaVoiceOpenGPTSoVITSV1ModelFileA(
        ppAilia!.value,
        encoder.toNativeUtf8().cast<ffi.Char>(),
        decoder1.toNativeUtf8().cast<ffi.Char>(),
        decoder2.toNativeUtf8().cast<ffi.Char>(),
        wave.toNativeUtf8().cast<ffi.Char>(),
        ssl.toNativeUtf8().cast<ffi.Char>(),
      );
    }
    throwError("ailiaVoiceOpenGPTSoVITSV1ModelFile", status);

    _finalizeOpen();
  }

  /// Opens a GPT-SoVITS V2 model.
  ///
  /// [encoder] is the path to the t2s_encoder model file.
  /// [decoder1] is the path to the t2s_fsdec model file.
  /// [decoder2] is the path to the t2s_sdec model file.
  /// [wave] is the path to the VITS model file.
  /// [ssl] is the path to the CNHuBERT SSL model file.
  /// [chineseBert] is the path to the Chinese BERT model file (optional).
  /// [vocab] is the path to the vocabulary file (optional).
  /// [envId] is the execution environment ID.
  void openGPTSoVITSV2Model(
    String encoder,
    String decoder1,
    String decoder2,
    String wave,
    String ssl,
    String? chineseBert,
    String? vocab,
    int envId,
  ) {
    _create(envId);

    int status;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceOpenGPTSoVITSV2ModelFileW(
        ppAilia!.value,
        encoder.toNativeUtf16().cast<ffi.WChar>(),
        decoder1.toNativeUtf16().cast<ffi.WChar>(),
        decoder2.toNativeUtf16().cast<ffi.WChar>(),
        wave.toNativeUtf16().cast<ffi.WChar>(),
        ssl.toNativeUtf16().cast<ffi.WChar>(),
        (chineseBert != null) ? chineseBert.toNativeUtf16().cast<ffi.WChar>() : ffi.nullptr,
        (vocab != null) ? vocab.toNativeUtf16().cast<ffi.WChar>() : ffi.nullptr,
      );
    }else{
      status = ailiaVoice.ailiaVoiceOpenGPTSoVITSV2ModelFileA(
        ppAilia!.value,
        encoder.toNativeUtf8().cast<ffi.Char>(),
        decoder1.toNativeUtf8().cast<ffi.Char>(),
        decoder2.toNativeUtf8().cast<ffi.Char>(),
        wave.toNativeUtf8().cast<ffi.Char>(),
        ssl.toNativeUtf8().cast<ffi.Char>(),
        (chineseBert != null) ? chineseBert.toNativeUtf8().cast<ffi.Char>() : ffi.nullptr,
        (vocab != null) ? vocab.toNativeUtf8().cast<ffi.Char>() : ffi.nullptr,
      );
    }
    throwError("ailiaVoiceOpenGPTSoVITSV2ModelFile", status);

    _finalizeOpen();
  }

  /// Opens a GPT-SoVITS V3 model.
  ///
  /// [encoder] is the path to the t2s_encoder model file.
  /// [decoder1] is the path to the t2s_fsdec model file.
  /// [decoder2] is the path to the t2s_sdec model file.
  /// [ssl] is the path to the CNHuBERT SSL model file.
  /// [vq] is the path to the VQ model file.
  /// [cfm] is the path to the CFM model file.
  /// [bigvgan] is the path to the BigVGAN model file.
  /// [chineseBert] is the path to the Chinese BERT model file (optional).
  /// [vocab] is the path to the vocabulary file (optional).
  /// [envId] is the execution environment ID.
  void openGPTSoVITSV3Model(
    String encoder,
    String decoder1,
    String decoder2,
    String ssl,
    String vq,
    String cfm,
    String bigvgan,
    String? chineseBert,
    String? vocab,
    int envId,
  ) {
    _create(envId);

    int status;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceOpenGPTSoVITSV3ModelFileW(
        ppAilia!.value,
        encoder.toNativeUtf16().cast<ffi.WChar>(),
        decoder1.toNativeUtf16().cast<ffi.WChar>(),
        decoder2.toNativeUtf16().cast<ffi.WChar>(),
        ssl.toNativeUtf16().cast<ffi.WChar>(),
        vq.toNativeUtf16().cast<ffi.WChar>(),
        cfm.toNativeUtf16().cast<ffi.WChar>(),
        bigvgan.toNativeUtf16().cast<ffi.WChar>(),
        (chineseBert != null) ? chineseBert.toNativeUtf16().cast<ffi.WChar>() : ffi.nullptr,
        (vocab != null) ? vocab.toNativeUtf16().cast<ffi.WChar>() : ffi.nullptr,
      );
    }else{
      status = ailiaVoice.ailiaVoiceOpenGPTSoVITSV3ModelFileA(
        ppAilia!.value,
        encoder.toNativeUtf8().cast<ffi.Char>(),
        decoder1.toNativeUtf8().cast<ffi.Char>(),
        decoder2.toNativeUtf8().cast<ffi.Char>(),
        ssl.toNativeUtf8().cast<ffi.Char>(),
        vq.toNativeUtf8().cast<ffi.Char>(),
        cfm.toNativeUtf8().cast<ffi.Char>(),
        bigvgan.toNativeUtf8().cast<ffi.Char>(),
        (chineseBert != null) ? chineseBert.toNativeUtf8().cast<ffi.Char>() : ffi.nullptr,
        (vocab != null) ? vocab.toNativeUtf8().cast<ffi.Char>() : ffi.nullptr,
      );
    }
    throwError("ailiaVoiceOpenGPTSoVITSV3ModelFile", status);

    _finalizeOpen();
  }

  /// Opens a GPT-SoVITS V2Pro model.
  ///
  /// [encoder] is the path to the t2s_encoder model file.
  /// [decoder1] is the path to the t2s_fsdec model file.
  /// [decoder2] is the path to the t2s_sdec model file.
  /// [ssl] is the path to the CNHuBERT SSL model file.
  /// [vits] is the path to the VITS model file.
  /// [sv] is the path to the speaker verification model file.
  /// [chineseBert] is the path to the Chinese BERT model file (optional).
  /// [vocab] is the path to the vocabulary file (optional).
  /// [envId] is the execution environment ID.
  void openGPTSoVITSV2ProModel(
    String encoder,
    String decoder1,
    String decoder2,
    String ssl,
    String vits,
    String sv,
    String? chineseBert,
    String? vocab,
    int envId,
  ) {
    _create(envId);

    int status;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceOpenGPTSoVITSV2ProModelFileW(
        ppAilia!.value,
        encoder.toNativeUtf16().cast<ffi.WChar>(),
        decoder1.toNativeUtf16().cast<ffi.WChar>(),
        decoder2.toNativeUtf16().cast<ffi.WChar>(),
        ssl.toNativeUtf16().cast<ffi.WChar>(),
        vits.toNativeUtf16().cast<ffi.WChar>(),
        sv.toNativeUtf16().cast<ffi.WChar>(),
        (chineseBert != null) ? chineseBert.toNativeUtf16().cast<ffi.WChar>() : ffi.nullptr,
        (vocab != null) ? vocab.toNativeUtf16().cast<ffi.WChar>() : ffi.nullptr,
      );
    }else{
      status = ailiaVoice.ailiaVoiceOpenGPTSoVITSV2ProModelFileA(
        ppAilia!.value,
        encoder.toNativeUtf8().cast<ffi.Char>(),
        decoder1.toNativeUtf8().cast<ffi.Char>(),
        decoder2.toNativeUtf8().cast<ffi.Char>(),
        ssl.toNativeUtf8().cast<ffi.Char>(),
        vits.toNativeUtf8().cast<ffi.Char>(),
        sv.toNativeUtf8().cast<ffi.Char>(),
        (chineseBert != null) ? chineseBert.toNativeUtf8().cast<ffi.Char>() : ffi.nullptr,
        (vocab != null) ? vocab.toNativeUtf8().cast<ffi.Char>() : ffi.nullptr,
      );
    }
    throwError("ailiaVoiceOpenGPTSoVITSV2ProModelFile", status);

    _finalizeOpen();
  }

  /// Sets the number of CFM sampling steps for V3 models.
  ///
  /// [steps] is the number of sampling steps (default is 4).
  void setSampleSteps(int steps) {
    int status = ailiaVoice.ailiaVoiceSetSampleSteps(ppAilia!.value, steps);
    throwError("ailiaVoiceSetSampleSteps", status);
  }

  /// Sets the speech speed for V2 and V3 models.
  ///
  /// [speed] is the speed multiplier (default is 1.0).
  void setSpeed(double speed) {
    int status = ailiaVoice.ailiaVoiceSetSpeed(ppAilia!.value, speed);
    throwError("ailiaVoiceSetSpeed", status);
  }

  /// Sets the G2P model type.
  ///
  /// [modelType] is the G2P model type constant.
  void setModelType(int modelType) {
    int status = ailiaVoice.ailiaVoiceSetModelType(ppAilia!.value, modelType);
    throwError("ailiaVoiceSetModelType", status);
  }

  /// Sets a user dictionary file.
  ///
  /// [dicFile] is the path to the user dictionary file.
  /// [dictionaryType] is the dictionary type constant.
  void setUserDictionary(
    String dicFile,
    int dictionaryType,
  ) {
    int status = 0;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceSetUserDictionaryFileW(
        ppAilia!.value,
        dicFile.toNativeUtf16().cast<ffi.WChar>(),
        dictionaryType,
      );
    }else{
      status = ailiaVoice.ailiaVoiceSetUserDictionaryFileA(
        ppAilia!.value,
        dicFile.toNativeUtf8().cast<ffi.Char>(),
        dictionaryType,
      );
    }
    throwError("ailiaVoiceSetUserDictionaryFile", status);
  }

  /// Opens a dictionary for G2P processing.
  ///
  /// [dicFolder] is the path to the dictionary folder.
  /// [dictionaryType] is the dictionary type constant
  /// (e.g., AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK, AILIA_VOICE_DICTIONARY_TYPE_G2P_EN).
  void openDictionary(
    String dicFolder,
    int dictionaryType,
  ) {
    int status = 0;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceOpenDictionaryFileW(
        ppAilia!.value,
        dicFolder.toNativeUtf16().cast<ffi.WChar>(),
        dictionaryType,
      );
    }else{
      status = ailiaVoice.ailiaVoiceOpenDictionaryFileA(
        ppAilia!.value,
        dicFolder.toNativeUtf8().cast<ffi.Char>(),
        dictionaryType,
      );
    }
    throwError("ailiaVoiceOpenDictionaryFile", status);
  }

  /// Opens a model and dictionary in a single call (for backward compatibility).
  ///
  /// Calls [openModel] followed by [openDictionary].
  void open(
    String encoder,
    String decoder1,
    String decoder2,
    String wave,
    String? ssl,
    String dicFolder,
    int modelType,
    int cleanerType,
    int dictionaryType,
    int envId,
  ) {
    openModel(encoder, decoder1, decoder2, wave, ssl, modelType, cleanerType, envId);
    openDictionary(dicFolder, dictionaryType);
  }

  /// Closes the model and releases native resources.
  void close() {
    if (!available){
      return;
    }

    ffi.Pointer<ailia_voice_dart.AILIAVoice> net = ppAilia!.value;
    ailiaVoice.ailiaVoiceDestroy(net);
    malloc.free(ppAilia!);

    available = false;
  }

  /// Performs grapheme-to-phoneme (G2P) conversion.
  ///
  /// Converts [inputText] to phoneme features using the specified [g2pType].
  /// Returns the phoneme feature string.
  String g2p(String inputText, int g2pType){
    if (debug){
      print("ailiaVoiceGraphemeToPhoeneme $inputText");
    }

    int status = ailiaVoice.ailiaVoiceGraphemeToPhoneme(
      ppAilia!.value,
      inputText.toNativeUtf8().cast<ffi.Char>(),
      g2pType,
    );
    throwError("ailiaVoiceGraphemeToPhoneme", status);

    final ffi.Pointer<ffi.UnsignedInt> len = malloc<ffi.UnsignedInt>();
    status = ailiaVoice.ailiaVoiceGetFeatureLength(ppAilia!.value, len);
    throwError("ailiaVoiceGetFeatureLength", status);
    if (debug){
      print("length ${len.value}");
    }

    final ffi.Pointer<ffi.Char> features = malloc<ffi.Char>(len.value);
    status = ailiaVoice.ailiaVoiceGetFeatures(
      ppAilia!.value,
      features,
      len.value,
    );
    throwError("ailiaVoiceGetFeatures", status);

    ffi.Pointer<Utf8> p = features.cast<Utf8>();
    String s = p.toDartString();
    if (debug){
      print("g2p output $s");
    }

    malloc.free(len);
    malloc.free(features);

    return s;
  }

  /// Sets the reference audio for voice cloning (GPT-SoVITS models).
  ///
  /// [pcm] is the PCM audio data as a list of float values.
  /// [sampleRate] is the sample rate of the reference audio in Hz.
  /// [nChannels] is the number of audio channels.
  /// [referenceFeature] is the phoneme feature string of the reference text.
  void setReference(List<double> pcm, int sampleRate, int nChannels, String referenceFeature){
    if (!available) {
      throw Exception("Model not opened yet. wait one second and try again.");
    }

    ffi.Pointer<ffi.Float> waveBuf = malloc<ffi.Float>(pcm.length);
    for (int i = 0; i < pcm.length; i++) {
      waveBuf[i] = pcm[i];
    }

    int status = ailiaVoice.ailiaVoiceSetReference(
      ppAilia!.value,
      waveBuf,
      pcm.length * 4,
      nChannels,
      sampleRate,
      referenceFeature.toNativeUtf8().cast<ffi.Char>()
    );
    throwError("ailiaVoiceSetReference", status);

    malloc.free(waveBuf);
  }

  /// Runs speech synthesis inference.
  ///
  /// [inputFeature] is the phoneme feature string to synthesize.
  /// Returns an [AiliaVoiceResult] containing the generated PCM audio data.
  AiliaVoiceResult inference(String inputFeature) {
    AiliaVoiceResult result = AiliaVoiceResult(
      sampleRate: 0,
      nChannels: 0,
      pcm: List<double>.empty(),
    );

    if (!available) {
      print("Model not opened");
      return result;
    }

    if (debug){
      print("ailiaVoiceInference");
    }

    int status = ailiaVoice.ailiaVoiceInference(ppAilia!.value, inputFeature.toNativeUtf8().cast<ffi.Char>());
    throwError("ailiaVoiceInference", status);

    if (debug){
      print("ailiaVoiceGetWaveInfo");
    }

    final ffi.Pointer<ffi.UnsignedInt> samples = malloc<ffi.UnsignedInt>();
    final ffi.Pointer<ffi.UnsignedInt> channels = malloc<ffi.UnsignedInt>();
    final ffi.Pointer<ffi.UnsignedInt> samplingRate = malloc<ffi.UnsignedInt>();

    status = ailiaVoice.ailiaVoiceGetWaveInfo(
      ppAilia!.value,
      samples,
      channels,
      samplingRate,
    );
    throwError("ailiaVoiceGetWaveInfo", status);

    if (debug){
      print("ailiaVoiceGetWaves");
    }

    final ffi.Pointer<ffi.Float> buf =
        malloc<ffi.Float>(samples.value * channels.value);

    int sizeofFloat = 4;
    status = ailiaVoice.ailiaVoiceGetWave(
      ppAilia!.value,
      buf,
      samples.value * channels.value * sizeofFloat,
    );
    throwError("ailiaVoiceGetWaves", status);

    List<double> pcm = List<double>.empty(growable: true);
    for (int i = 0; i < samples.value * channels.value; i++) {
      pcm.add(buf[i]);
    }

    AiliaVoiceResult resultPcm = AiliaVoiceResult(
      sampleRate: samplingRate.value,
      nChannels: channels.value,
      pcm: pcm,
    );

    if (debug){
      print(
          "ailiaVoice output ${samples.value} ${samplingRate.value} ${channels.value}");
    }

    malloc.free(buf);
    malloc.free(samples);
    malloc.free(channels);
    malloc.free(samplingRate);

    return resultPcm;
  }
}
