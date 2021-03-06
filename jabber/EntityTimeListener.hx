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
package jabber;

/**
	<a href="http://www.xmpp.org/extensions/xep-0202.html">XEP 202 - EntityTime</a><br/>
	Listens/Answers entity time requests.
*/
class EntityTimeListener {
	
	public var stream(default,null) : Stream;
	public var time(default,null) : xmpp.EntityTime;
	
	var c : jabber.stream.PacketCollector;
	
	public function new( stream : Stream, ?tzo : String = "00:00" ) {
		if( !stream.features.add( xmpp.EntityTime.XMLNS ) )
			throw "entitytime listener already added";
		this.stream = stream;
		time = new xmpp.EntityTime( tzo );
		c = stream.collect( [new xmpp.filter.IQFilter(xmpp.EntityTime.XMLNS,xmpp.IQType.get,"time")], handleRequest, true );
	}
	
	public function dispose() {
		stream.removeCollector( c );
		stream.features.remove( xmpp.EntityTime.XMLNS );
	}
	
	function handleRequest( iq : xmpp.IQ ) {
		var r = xmpp.IQ.createResult( iq );
		time.utc = xmpp.DateTime.now();
		r.x = time;
		stream.sendPacket( r );	
	}
	
}
