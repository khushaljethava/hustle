import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';

// Events
abstract class ClientEvent extends Equatable {
  const ClientEvent();
  @override
  List<Object?> get props => [];
}

class LoadClients extends ClientEvent {}

class CreateClient extends ClientEvent {
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final double defaultRate;
  final String currency;
  final String? notes;

  const CreateClient({
    required this.name,
    this.email,
    this.phone,
    this.company,
    required this.defaultRate,
    required this.currency,
    this.notes,
  });

  @override
  List<Object?> get props => [name, email, defaultRate];
}

class UpdateClient extends ClientEvent {
  final ClientModel client;
  const UpdateClient(this.client);
  @override
  List<Object?> get props => [client];
}

class ArchiveClient extends ClientEvent {
  final String clientId;
  const ArchiveClient(this.clientId);
  @override
  List<Object?> get props => [clientId];
}

class DeleteClient extends ClientEvent {
  final String clientId;
  const DeleteClient(this.clientId);
  @override
  List<Object?> get props => [clientId];
}

// States
abstract class ClientState extends Equatable {
  const ClientState();
  @override
  List<Object?> get props => [];
}

class ClientInitial extends ClientState {}
class ClientLoading extends ClientState {}

class ClientLoaded extends ClientState {
  final List<ClientModel> clients;
  const ClientLoaded(this.clients);
  @override
  List<Object?> get props => [clients];
}

class ClientError extends ClientState {
  final String message;
  const ClientError(this.message);
  @override
  List<Object?> get props => [message];
}

class ClientOperationSuccess extends ClientState {
  final String message;
  final List<ClientModel> clients;
  const ClientOperationSuccess({required this.message, required this.clients});
  @override
  List<Object?> get props => [message, clients];
}

// BLoC
class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final ClientRepository _repository;

  ClientBloc(this._repository) : super(ClientInitial()) {
    on<LoadClients>(_onLoad);
    on<CreateClient>(_onCreate);
    on<UpdateClient>(_onUpdate);
    on<ArchiveClient>(_onArchive);
    on<DeleteClient>(_onDelete);
  }

  Future<void> _onLoad(LoadClients event, Emitter<ClientState> emit) async {
    emit(ClientLoading());
    try {
      final clients = await _repository.getAll();
      emit(ClientLoaded(clients));
    } catch (e) {
      emit(ClientError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateClient event, Emitter<ClientState> emit) async {
    try {
      await _repository.create(
        name: event.name,
        email: event.email,
        phone: event.phone,
        company: event.company,
        defaultRate: event.defaultRate,
        currency: event.currency,
        notes: event.notes,
      );
      final clients = await _repository.getAll();
      emit(ClientOperationSuccess(message: 'Client added', clients: clients));
    } catch (e) {
      emit(ClientError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateClient event, Emitter<ClientState> emit) async {
    try {
      await _repository.update(event.client);
      final clients = await _repository.getAll();
      emit(ClientOperationSuccess(message: 'Client updated', clients: clients));
    } catch (e) {
      emit(ClientError(e.toString()));
    }
  }

  Future<void> _onArchive(ArchiveClient event, Emitter<ClientState> emit) async {
    try {
      await _repository.archive(event.clientId);
      final clients = await _repository.getAll();
      emit(ClientOperationSuccess(message: 'Client archived', clients: clients));
    } catch (e) {
      emit(ClientError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteClient event, Emitter<ClientState> emit) async {
    try {
      await _repository.delete(event.clientId);
      final clients = await _repository.getAll();
      emit(ClientOperationSuccess(message: 'Client deleted', clients: clients));
    } catch (e) {
      emit(ClientError(e.toString()));
    }
  }
}
