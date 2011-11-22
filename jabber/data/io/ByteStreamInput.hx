/*
 *	This file is part of HXMPP.
 *	Copyright (c)2009 http://www.disktree.net
 *	
 *	HXMPP is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  HXMPP is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *	See the GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with HXMPP. If not, see <http://www.gnu.org/licenses/>.
*/
package jabber.data.io;

import haxe.io.Bytes;
import jabber.util.SOCKS5Output;
#if neko
import neko.net.Host;
import neko.net.Socket;
import neko.vm.Thread;
#elseif cpp
import cpp.net.Host;
import cpp.net.Socket;
import cpp.vm.Thread;
#elseif (flash)
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;
import flash.net.Socket;
import flash.utils.ByteArray;
#elseif (air&&js)
import air.ServerSocketConnectEvent;
import air.Socket;
import air.ServerSocket;
import air.ByteArray;
//#elseif (js&&!nodejs)
//import WebSocket;
//private typedef Socket = WebSocket;
#elseif nodejs
import js.Node;
private typedef Socket = Stream;
#end

/**
	SOCKS5 bytestream input.
*/
class ByteStreamInput extends ByteStreamIO {
	
	public var __onConnect : Void->Void;
	public var __onProgress : Bytes->Void;
	
	var socket : Socket;
	
	#if (neko||cpp)
	var buf : Bytes;
	
	#elseif flash
	var buf : ByteArray;
	
	#elseif nodejs
	var buf : Buffer;
	#end
	
	#if (flash||nodejs)
	var digest : String;
	var size : Int;
	var bufpos : Int;
	#end
	
	public function new( host : String, port : Int ) {
		super( host, port );
	}
	
	public function connect( digest : String, size : Int, ?range : xmpp.file.Range, bufsize : Int = 4096 ) {
		
		#if JABBER_DEBUG
		trace( "Connecting to filetransfer streamhost ["+host+":"+port+"]" );
		#end
		
		#if (neko||cpp)
		socket = new Socket();
		try {
			socket.connect( new Host( host ), port );
			new SOCKS5Output().run( socket, digest );
		} catch( e : Dynamic ) {
			__onFail( e );
			return;
		}
		var t = Thread.create( read );
		t.sendMessage( Thread.current() );
		t.sendMessage( socket.input );
		t.sendMessage( size );
		t.sendMessage( bufsize );
		t.sendMessage( __onProgress );
		t.sendMessage( completeCallback );
		Thread.readMessage( true );
		__onConnect();
		
		#elseif flash
		this.digest = digest;
		this.size = size;
		socket = new Socket();
		socket.addEventListener( Event.CONNECT, onSocketConnect  );
		socket.addEventListener( Event.CLOSE, onSocketDisconnect );
		socket.addEventListener( IOErrorEvent.IO_ERROR, onSocketError );
		socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSocketError );
		socket.connect( host, port );
		
		/*
		#elseif (js&&!nodejs)
		if( untyped js.Lib.window.WebSocket == null ) {
			__onFail( "No websocket support" );
			return;
		}
		socket = new Socket( "ws"+"://"+host+":"+port );
		socket.onopen = onConnect;
		socket.onclose = onClose;
		socket.onerror = onError;
		*/
		
		#elseif nodejs
		this.digest = digest;
		this.size = size;
		socket = Node.net.createConnection( port, host );
		socket.on( Node.STREAM_CONNECT, sockConnectHandler );
		socket.on( Node.STREAM_END, sockDisconnectHandler );
		socket.on( Node.STREAM_ERROR, sockErrorHandler );
		
		#end
	}
	
	
	#if (neko||cpp)
	
	function completeCallback( err : String ) {
		cleanup();
		if( err == null ) {
			__onComplete();
		} else {
			__onFail( err );
		}
	}
	
	function read() {
		var main : Thread = Thread.readMessage( true );
		var input : haxe.io.Input = Thread.readMessage( true );
		var size : Int = Thread.readMessage( true );
		var bufsize : Int = Thread.readMessage( true );
		var onProgress : Bytes->Void = Thread.readMessage( true );
		var cb : String->Void = Thread.readMessage( true );
		main.sendMessage( true );
		var pos = 0;
		while( pos < size ) {
			var remain = size-pos;
			var len = ( remain > bufsize ) ? bufsize : remain;
			//var bytes = Bytes.alloc( len );
			var bytes : Bytes = null;
			try {
				bytes = input.read( len );
				pos += len;
				//pos += input.readBytes( bytes, 0, len );
				//pos += len;
			} catch( e : Dynamic ) {
				trace(e);
				cb( e );
				return;
			}
			onProgress( bytes );
		}
		cb( null);
	}
	
	function cleanup() {
		if( socket != null ) try socket.close() catch( e : Dynamic ) { #if JABBER_DEBUG trace(e); #end }
	}
	
	/*
	#elseif (js&&!nodejs)
	
	function onConnect() {
		trace("onConnectonConnectonConnectonConnect");
	}
	
	function onClose() {
		trace("onClose");
	}
	
	function onError() {
		trace("onError");
	}
	*/
	
	#elseif flash
	
	function onSocketConnect( e : Event ) {
		#if JABBER_DEBUG trace( "Filetransfer socket connected ["+host+":"+port+"]", "info" ); #end
		try {
			new SOCKS5Output().run( socket, digest, onSOCKS5Complete );
		} catch( e : Dynamic ) {
			cleanup();
			__onFail( e );
		}
	}
	
	function onSOCKS5Complete( err : String ) {
		if( err != null ) {
			#if JABBER_DEBUG trace( "SOCKS5 negotiation failed: "+err ); #end
			cleanup();
			__onFail( err );
		} else {
			#if JABBER_DEBUG trace( "SOCKS5 negotiation complete" ); #end
			buf = new ByteArray();
			bufpos = 0;
			socket.addEventListener( ProgressEvent.SOCKET_DATA, onSocketData );
			__onConnect();
		}
	}
	
	function onSocketDisconnect( e : Event ) {
		cleanup();
		__onFail( e.type );
	}
	
	function onSocketError( e : Event ) {
		cleanup();
		__onFail( e.type );
	}
	
	function onSocketData( e : ProgressEvent ) {
		var b = new ByteArray();
		socket.readBytes( b, 0, Std.int(e.bytesLoaded) );
		bufpos += b.length;
		__onProgress( Bytes.ofData( b ) );
		if( bufpos == size ) {
			cleanup();
			__onComplete();
		}
	}
	
	function cleanup() {
		socket.removeEventListener( Event.CONNECT, onSocketConnect );
		socket.removeEventListener( Event.CLOSE, onSocketDisconnect );
		socket.removeEventListener( IOErrorEvent.IO_ERROR, onSocketError );
		socket.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onSocketError );
		socket.removeEventListener( ProgressEvent.SOCKET_DATA, onSocketData );
		if( socket.connected ) socket.close();
	}
	
	
	#elseif nodejs
	
	function sockConnectHandler() {
		#if JABBER_DEBUG trace( "Filetransfer socket connected ["+host+":"+port+"]" ); #end
		new SOCKS5Output().run( socket, digest, onSOCKS5Complete );
	}

	function sockDisconnectHandler() {
		cleanup();
	}

	function sockErrorHandler() {
		cleanup();
		__onFail( "bytestream inut failed" );
	}

	function sockDataHandler( b : Buffer ) {
		__onProgress( Bytes.ofData(b) );
		if( ( bufpos += b.length ) == size ) {
			cleanup();
			__onComplete();
		}
	}

	function onSOCKS5Complete( err : String ) {
		if( err != null ) {
			cleanup();
			__onFail( err );
		} else {
			#if JABBER_DEBUG trace( "SOCKS5 negotiation complete " ); #end
			bufpos = 0;
			socket.on( Node.STREAM_DATA, sockDataHandler );
			__onConnect();
		}
	}

	function cleanup() {
		socket.removeAllListeners( Node.STREAM_CONNECT );
		socket.removeAllListeners( Node.STREAM_DATA );
		socket.removeAllListeners( Node.STREAM_END );
		socket.removeAllListeners( Node.STREAM_ERROR );
		socket.end();
	}
	
	#end
	
}
